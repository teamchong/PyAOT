#!/bin/bash
# Test different allocation strategies

echo "=== Allocation Strategy Testing ==="

# Baseline
echo ""
echo "[1/4] Baseline (current implementation)"
/usr/bin/time -l ./zig-out/bin/tokenizer_bench 2>&1 | grep -E "(real|user|sys|page reclaims|page faults)"

# We'll manually test variants by modifying code and rebuilding
# This script documents the test plan

echo ""
echo "Test plan:"
echo "- Baseline: Current implementation"
echo "- Test 1: Remove cache (comment out cache get/put)"
echo "- Test 2: Increase ArrayList prealloc (text.len/4 → text.len)"
echo "- Test 3: Switch to c_allocator"
echo "- Test 4: Best combination"
