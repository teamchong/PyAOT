#!/bin/bash
# Hyperfine benchmark: PyAOT vs tiktoken (encoding only)

set -e

echo "⚡ Encoding Benchmark: PyAOT vs tiktoken"
echo "============================================================"

# Build if needed
if [ ! -f zig-out/bin/bench_native ]; then
    echo "Building bench_native..."
    zig build-exe src/bench_native.zig -O ReleaseFast
    mv bench_native zig-out/bin/
fi

# Create tiktoken benchmark wrapper
cat > /tmp/bench_tiktoken.py << 'PYEOF'
import time
import tiktoken

TEXT = """The cat sat on the mat. The dog ran in the park. The bird flew in the sky. The fish swam in the sea. The snake slithered on the ground. The rabbit hopped in the field. The fox ran through the forest. The bear climbed the tree. The wolf howled at the moon. The deer grazed in the meadow."""

enc = tiktoken.get_encoding("cl100k_base")

# Warmup
for _ in range(1000):
    enc.encode(TEXT)

# Benchmark
iterations = 60000
start = time.time()
for _ in range(iterations):
    tokens = enc.encode(TEXT)
elapsed = time.time() - start

print(f"{int(elapsed * 1000)}ms")
PYEOF

# Run hyperfine
hyperfine \
    --warmup 3 \
    --runs 10 \
    --export-markdown bench_encoding_results.md \
    --command-name "PyAOT (Zig)" './zig-out/bin/bench_native' \
    --command-name "tiktoken (Rust)" 'python3 /tmp/bench_tiktoken.py'

echo ""
echo "📊 Results saved to bench_encoding_results.md"
