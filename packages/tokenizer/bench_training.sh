#!/bin/bash
# Hyperfine benchmark: BPE Training (PyAOT vs HuggingFace vs SentencePiece)

set -e

echo "⚡ BPE Training Benchmark (hyperfine)"
echo "============================================================"
echo "Training: 150K texts, vocab 2048"
echo ""

# Build bench_train if needed
if [ ! -f zig-out/bin/bench_train ]; then
    echo "Building bench_train..."
    zig build-exe src/bench_train.zig -O ReleaseFast
    mv bench_train zig-out/bin/
fi

cat > /tmp/bench_hf_train.py << 'PYEOF'
import time
from tokenizers import Tokenizer, models, trainers

TEXT_COUNT = 150_000
VOCAB_SIZE = 2048

texts = ["The quick brown fox jumps over the lazy dog"] * TEXT_COUNT
tokenizer = Tokenizer(models.BPE(unk_token="[UNK]"))
trainer = trainers.BpeTrainer(
    vocab_size=VOCAB_SIZE,
    special_tokens=["[UNK]", "[PAD]"]
)

start = time.time()
tokenizer.train_from_iterator(texts, trainer=trainer)
elapsed = time.time() - start

print(f"{int(elapsed * 1000)}ms")
PYEOF

cat > /tmp/bench_spm_train.py << 'PYEOF'
import time
import sentencepiece as spm
import tempfile
import os

TEXT_COUNT = 150_000

# Write training data
with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
    for _ in range(TEXT_COUNT):
        f.write("The quick brown fox jumps over the lazy dog\n")
    temp_file = f.name

# Train
start = time.time()
spm.SentencePieceTrainer.train(
    input=temp_file,
    model_prefix='temp_spm',
    vocab_size=100,  # BPE mode limit
    model_type='bpe'
)
elapsed = time.time() - start

# Cleanup
os.unlink(temp_file)
if os.path.exists('temp_spm.model'):
    os.unlink('temp_spm.model')
if os.path.exists('temp_spm.vocab'):
    os.unlink('temp_spm.vocab')

print(f"{int(elapsed * 1000)}ms")
PYEOF

# Run hyperfine
hyperfine \
    --warmup 1 \
    --runs 5 \
    --export-markdown bench_training_results.md \
    --command-name "PyAOT (Zig)" './zig-out/bin/bench_train' \
    --command-name "HuggingFace (Rust)" 'python3 /tmp/bench_hf_train.py' \
    --command-name "SentencePiece (C++)" 'python3 /tmp/bench_spm_train.py'

echo ""
echo "📊 Results saved to bench_training_results.md"
