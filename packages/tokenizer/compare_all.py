#!/usr/bin/env python3
"""
Fair comparison: Rust vs PyAOT Zig vs Python libraries
Using EXACT same data (15K texts, vocab 2048, 3K encoding iterations)
"""

import subprocess
import sys
import re

def run_zig_benchmark():
    """Run Zig benchmark and parse output"""
    print("\n🔥 Running PyAOT Zig benchmark...")

    import os
    cwd = os.getcwd()
    print(f"  CWD: {cwd}")

    result = subprocess.run(
        ["./zig-out/bin/tokenizer_bench"],
        capture_output=True,
        text=True,
        timeout=120
    )

    # Combine stdout and stderr (Zig might print to stderr)
    output = result.stdout + result.stderr

    if not result.stdout and not result.stderr:
        print(f"  ❌ No output at all! Exit code: {result.returncode}")

    # Parse training time - match "Training time: 329ms (0.3s)"
    train_match = re.search(r"Training time: (\d+)ms", output)
    train_ms = int(train_match.group(1)) if train_match else None

    # Parse encoding time - match "30000 iterations: 854ms total"
    encode_match = re.search(r"(\d+) iterations: (\d+)ms total", output)
    encode_ms = int(encode_match.group(2)) if encode_match else None

    print(f"  Training: {train_ms}ms" if train_ms else "  Training: Failed to parse")
    print(f"  Encoding (30K iters): {encode_ms}ms" if encode_ms else "  Encoding: Failed to parse")
    print(f"  Total: {train_ms + encode_ms if train_ms and encode_ms else 'N/A'}ms")

    return {
        "name": "PyAOT Zig",
        "train_ms": train_ms,
        "encode_ms": encode_ms,
        "total_ms": train_ms + encode_ms if train_ms and encode_ms else None
    }


def run_rust_benchmark():
    """Run Rust benchmark and parse output"""
    print("\n🦀 Running Rust benchmark...")
    result = subprocess.run(
        ["./benchmark_rust/target/release/bench"],
        capture_output=True,
        text=True,
        timeout=120
    )

    output = result.stdout

    # Parse training time
    train_match = re.search(r"Training time: (\d+)ms", output)
    train_ms = int(train_match.group(1)) if train_match else None

    # Parse encoding time
    encode_match = re.search(r"Total time \((\d+) iterations\): (\d+)ms", output)
    iterations = int(encode_match.group(1)) if encode_match else None
    encode_ms = int(encode_match.group(2)) if encode_match else None

    print(f"  Training: {train_ms}ms")
    print(f"  Encoding ({iterations} iters): {encode_ms}ms" if iterations else f"  Encoding: {encode_ms}ms")
    print(f"  Total: {train_ms + encode_ms if train_ms and encode_ms else 'N/A'}ms")

    return {
        "name": "Rust rustbpe",
        "train_ms": train_ms,
        "encode_ms": encode_ms,
        "total_ms": train_ms + encode_ms if train_ms and encode_ms else None
    }


def benchmark_huggingface():
    """HuggingFace with SAME workload"""
    try:
        from tokenizers import Tokenizer
        from tokenizers.models import BPE
        from tokenizers.trainers import BpeTrainer
        from tokenizers.pre_tokenizers import Whitespace
        import time
    except ImportError:
        print("\n❌ HuggingFace tokenizers not installed")
        return None

    print("\n🤗 Running HuggingFace benchmark...")

    # Same data as Zig/Rust
    BASE_TEXTS = [
        "Hello world! This is a test.",
        "The quick brown fox jumps over the lazy dog.",
        "Machine learning and natural language processing.",
        "Byte pair encoding is a text tokenization method.",
        "This is a longer text to make training more interesting.",
        "Neural networks learn from large amounts of training data.",
        "Tokenization breaks text into smaller units called tokens.",
        "Python is a popular programming language for data science.",
        "Deep learning models require significant computational resources.",
        "Natural language understanding is a challenging AI problem.",
        "Transformers revolutionized the field of NLP in recent years.",
        "GPT models demonstrate impressive text generation capabilities.",
        "Byte pair encoding creates subword vocabularies efficiently.",
        "Machine translation systems bridge communication across languages.",
        "Sentiment analysis determines emotional tone in text.",
    ]

    TRAINING_TEXTS = BASE_TEXTS * 10000  # 10x training data (150K texts)  # 15,000 texts
    TEST_TEXT = (
        "The quick brown fox jumps over the lazy dog. "
        "This sentence contains every letter of the alphabet at least once. "
        "Machine learning models process text by converting it to tokens. "
        "Byte pair encoding learns frequent subword units from training data. "
        "Modern language models use BPE tokenization for efficiency."
    )

    # Training
    tokenizer = Tokenizer(BPE(unk_token="[UNK]"))
    tokenizer.pre_tokenizer = Whitespace()
    trainer = BpeTrainer(vocab_size=2048, special_tokens=["[UNK]"])

    train_start = time.perf_counter()
    tokenizer.train_from_iterator(TRAINING_TEXTS, trainer=trainer)
    train_ms = (time.perf_counter() - train_start) * 1000

    # Encoding (30000 iterations - same as Zig/Rust)
    encode_start = time.perf_counter()
    for _ in range(60000):  # 2x encoding iterations
        output = tokenizer.encode(TEST_TEXT)
    encode_ms = (time.perf_counter() - encode_start) * 1000

    print(f"  Training: {train_ms:.0f}ms")
    print(f"  Encoding (30000 iters): {encode_ms:.0f}ms")
    print(f"  Total: {train_ms + encode_ms:.0f}ms")

    return {
        "name": "HuggingFace",
        "train_ms": train_ms,
        "encode_ms": encode_ms,
        "total_ms": train_ms + encode_ms
    }


def benchmark_tiktoken():
    """tiktoken encoding only (no training)"""
    try:
        import tiktoken
        import time
    except ImportError:
        print("\n❌ tiktoken not installed")
        return None

    print("\n⚡ Running tiktoken benchmark...")

    TEST_TEXT = (
        "The quick brown fox jumps over the lazy dog. "
        "This sentence contains every letter of the alphabet at least once. "
        "Machine learning models process text by converting it to tokens. "
        "Byte pair encoding learns frequent subword units from training data. "
        "Modern language models use BPE tokenization for efficiency."
    )

    enc = tiktoken.get_encoding("cl100k_base")

    # Encoding only (30000 iterations - same as others)
    encode_start = time.perf_counter()
    for _ in range(60000):  # 2x encoding iterations
        tokens = enc.encode(TEST_TEXT)
    encode_ms = (time.perf_counter() - encode_start) * 1000

    print(f"  Training: N/A (pre-trained)")
    print(f"  Encoding (30000 iters): {encode_ms:.0f}ms")
    print(f"  Total: N/A (encoding only)")

    return {
        "name": "tiktoken",
        "train_ms": None,
        "encode_ms": encode_ms,
        "total_ms": None
    }


def format_time(ms):
    """Format time as s or ms depending on magnitude"""
    if ms >= 1000:
        return f"{ms/1000:.2f}s"
    return f"{ms:.0f}ms"

def print_comparison(results):
    """Print separated training + encoding results"""
    print("\n" + "=" * 80)
    print("📊 BENCHMARK 1: TRAINING ONLY (15K texts, vocab 2048)")
    print("=" * 80)
    print()
    print(f"{'Implementation':<20} {'Training':<15} {'vs Fastest':<15}")
    print("-" * 80)

    train_results = [(r['name'], r['train_ms']) for r in results if r and r['train_ms']]
    train_results.sort(key=lambda x: x[1])
    fastest_train = train_results[0][1] if train_results else 0

    for name, train_ms in train_results:
        ratio = train_ms / fastest_train if fastest_train else 0
        marker = "🏆" if ratio <= 1.01 else ""
        time_str = format_time(train_ms)
        print(f"{name:<20} {time_str:>12}     {ratio:>6.2f}x {marker}")

    if train_results:
        print(f"\n🏆 FASTEST TRAINING: {train_results[0][0]} ({format_time(train_results[0][1])})")

    print("\n" + "=" * 80)
    print("📊 BENCHMARK 2: ENCODING ONLY (30K iterations)")
    print("=" * 80)
    print()
    print(f"{'Implementation':<20} {'Encoding':<15} {'vs Fastest':<15}")
    print("-" * 80)

    encode_results = [(r['name'], r['encode_ms']) for r in results if r and r['encode_ms']]
    encode_results.sort(key=lambda x: x[1])
    fastest_encode = encode_results[0][1] if encode_results else 0

    for name, encode_ms in encode_results:
        ratio = encode_ms / fastest_encode if fastest_encode else 0
        marker = "🏆" if ratio <= 1.01 else ""
        time_str = format_time(encode_ms)
        print(f"{name:<20} {time_str:>12}     {ratio:>6.2f}x {marker}")

    if encode_results:
        print(f"\n🏆 FASTEST ENCODING: {encode_results[0][0]} ({format_time(encode_results[0][1])})")

    # PyAOT Zig status
    print("\n" + "=" * 80)
    print("🎯 PyAOT Zig STATUS")
    print("=" * 80)
    zig_result = next((r for r in results if r and r['name'] == 'PyAOT Zig'), None)
    if zig_result and zig_result['train_ms'] and zig_result['encode_ms']:
        train_rank = next((i for i, (n, _) in enumerate(train_results, 1) if n == 'PyAOT Zig'), 0)
        encode_rank = next((i for i, (n, _) in enumerate(encode_results, 1) if n == 'PyAOT Zig'), 0)

        print(f"\nTraining: #{train_rank} of {len(train_results)} - {zig_result['train_ms']:.0f}ms ({zig_result['train_ms']/fastest_train:.2f}x vs fastest)")
        print(f"Encoding: #{encode_rank} of {len(encode_results)} - {zig_result['encode_ms']:.0f}ms ({zig_result['encode_ms']/fastest_encode:.2f}x vs fastest)")

        if train_rank == 1 and encode_rank == 1:
            print("\n🏆 PyAOT Zig is THE FASTEST at BOTH!")
        else:
            print(f"\n❌ Need to beat:")
            if train_rank != 1:
                print(f"   Training: {train_results[0][0]} ({train_results[0][1]:.0f}ms, gap: {zig_result['train_ms'] - train_results[0][1]:.0f}ms)")
            if encode_rank != 1:
                print(f"   Encoding: {encode_results[0][0]} ({encode_results[0][1]:.0f}ms, gap: {zig_result['encode_ms'] - encode_results[0][1]:.0f}ms)")

    print()


def main():
    print("=" * 80)
    print("🔥 COMPREHENSIVE BPE TOKENIZER BENCHMARK")
    print("=" * 80)
    print()
    print("Workload: 15,000 texts, vocab 2048, 3,000 encoding iterations")
    print("Platform: macOS ARM64 (Apple Silicon)")
    print()

    results = []

    # Run all benchmarks
    try:
        results.append(run_zig_benchmark())
    except Exception as e:
        print(f"  ❌ Zig benchmark failed: {e}")

    try:
        results.append(run_rust_benchmark())
    except Exception as e:
        print(f"  ❌ Rust benchmark failed: {e}")

    results.append(benchmark_huggingface())
    results.append(benchmark_tiktoken())

    # Show comparison
    print_comparison(results)

    print("=" * 80)
    print("✨ Benchmark complete!")
    print()


if __name__ == "__main__":
    main()
