# Tokenizer Benchmark Results

**Platform:** macOS ARM64 (Apple Silicon)
**Date:** 2024-11-19
**Zig:** 0.15.2
**Build:** --release=fast

---

## Hyperfine Results (10 runs, same workload)

| Implementation | Mean | Std Dev | Range | Relative |
|----------------|------|---------|-------|----------|
| **Rust baseline** | **513.8ms** | ±8.0ms | 501-523ms | **1.00x** ✅ |
| **Zig PyAOT** | **4.629s** | ±121ms | 4.47-4.89s | **9.0x slower** ❌ |

**Workload:** 15K texts training (vocab 2048) + 3K encoding iterations

**Why 9x slower:**
1. **Training:** Rust uses rayon (parallel), Zig single-threaded
2. **Encoding:** Wrong algorithm - rescanning tokens instead of applying merges in order

**Next:** Fix encoding algorithm to match Rust (apply all merges in order once)
