#!/bin/bash
# Startup time benchmark: 4-Language comparison (Hello World)
set -e

echo "⚡ Startup Time Benchmark: 4-Language Comparison"
echo "================================================="
echo "Measuring pure startup overhead (Hello World)"
echo ""

# Pre-compile PyAOT binary
if [ ! -f ../.pyaot/hello ]; then
    echo "Compiling PyAOT binary..."
    cd ..
    pyaot build benchmarks/hello.py --binary
    cd benchmarks
    echo ""
fi

# Run hyperfine benchmark
hyperfine \
    --warmup 10 \
    --runs 100 \
    --shell=none \
    --export-markdown bench_startup_results.md \
    --command-name "PyAOT (Zig)" '../.pyaot/hello' \
    --command-name "Rust 1.91" './hello_rust' \
    --command-name "Go 1.25" './hello_go' \
    --command-name "CPython 3.13" 'python3 hello.py'

echo ""
echo "📊 Results saved to bench_startup_results.md"
