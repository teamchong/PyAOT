#!/usr/bin/env python3
"""
BPE Training Benchmark: PyAOT vs HuggingFace tokenizers
"""
import time

# Same training data as PyAOT (150K texts, vocab 2048)
TEXT_COUNT = 150_000
VOCAB_SIZE = 2048

print("🚀 BPE Training Benchmark")
print("=" * 60)
print(f"Training with {TEXT_COUNT:,} texts, vocab {VOCAB_SIZE}")
print()

# PyAOT result (from previous run)
pyaot_ms = 26
print(f"1. PyAOT (Zig): {pyaot_ms}ms")
print()

# Benchmark 2: HuggingFace tokenizers (Rust)
print("2. HuggingFace tokenizers (Rust)...")
try:
    from tokenizers import Tokenizer, models, trainers

    # Generate training data (same as PyAOT)
    texts = ["The quick brown fox jumps over the lazy dog"] * TEXT_COUNT

    # Setup tokenizer
    tokenizer = Tokenizer(models.BPE(unk_token="[UNK]"))
    trainer = trainers.BpeTrainer(
        vocab_size=VOCAB_SIZE,
        special_tokens=["[UNK]", "[PAD]"]
    )

    # Benchmark training
    start = time.time()
    tokenizer.train_from_iterator(texts, trainer=trainer)
    elapsed_hf = (time.time() - start) * 1000

    print(f"   Time: {int(elapsed_hf)}ms")
except ImportError:
    print("   ❌ tokenizers not installed (pip install tokenizers)")
    elapsed_hf = None

# Benchmark 3: SentencePiece (Google, C++)
print("3. SentencePiece (Google, C++)...")
try:
    import sentencepiece as spm
    import tempfile
    import os

    # Write training data to temp file
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
        for _ in range(TEXT_COUNT):
            f.write("The quick brown fox jumps over the lazy dog\n")
        temp_file = f.name

    # Benchmark training (SentencePiece BPE has max vocab_size=100)
    start = time.time()
    spm.SentencePieceTrainer.train(  # type: ignore
        input=temp_file,
        model_prefix='temp_spm',
        vocab_size=min(VOCAB_SIZE, 100),  # BPE mode limit
        model_type='bpe'
    )
    elapsed_spm = (time.time() - start) * 1000

    # Cleanup
    os.unlink(temp_file)
    os.unlink('temp_spm.model')
    os.unlink('temp_spm.vocab')

    print(f"   Time: {int(elapsed_spm)}ms")
except ImportError:
    print("   ❌ sentencepiece not installed (pip install sentencepiece)")
    elapsed_spm = None
except Exception as e:
    print(f"   ❌ Error: {e}")
    elapsed_spm = None

print()
print("=" * 60)
print("Results:")
print("-" * 60)

results = [("PyAOT (Zig)", pyaot_ms)]
if elapsed_hf:
    results.append(("HuggingFace (Rust)", int(elapsed_hf)))
if elapsed_spm:
    results.append(("SentencePiece (C++)", int(elapsed_spm)))

# Sort by time
results.sort(key=lambda x: x[1])

for i, (name, ms) in enumerate(results):
    speedup = ms / results[0][1]
    trophy = " 🏆" if i == 0 else ""
    print(f"{name:<25} {ms:>6}ms   {speedup:>5.2f}x{trophy}")
