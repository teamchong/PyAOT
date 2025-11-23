#!/bin/bash
# Fibonacci(45) benchmark: CPython vs PyAOT vs Go vs Rust
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Fibonacci(45) Benchmark: 4-Language Comparison"
echo "=================================================="
echo "Computing fibonacci(45) = 1134903170"
echo "Expected runtime: ~60s (CPython), ~5-7s (PyAOT), ~3-4s (Go), ~2-3s (Rust)"
echo ""

# Run hyperfine benchmark
cd "$SCRIPT_DIR"
hyperfine \
    --warmup 1 \
    --runs 3 \
    --export-markdown bench_fibonacci_results.md \
    --command-name "CPython 3.13" 'python3 fibonacci.py' \
    --command-name "PyAOT (Zig)" "cd $REPO_ROOT && pyaot benchmarks/fibonacci.py" \
    --command-name "Go 1.25" './fibonacci_go' \
    --command-name "Rust 1.91" './fibonacci_rust'

echo ""
echo "📊 Results saved to bench_fibonacci_results.md"
