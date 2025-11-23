/// SIMD-accelerated tokenization using Zig's @Vector
/// Leverages Zig's first-class SIMD support for parallel pattern matching
const std = @import("std");
const Allocator = std.mem.Allocator;

/// SIMD vector size - process 32 bytes in parallel
const SIMD_WIDTH = 32;
const Vec32u8 = @Vector(SIMD_WIDTH, u8);
const Vec32bool = @Vector(SIMD_WIDTH, bool);

/// Special byte patterns we can detect with SIMD
pub const ByteClass = enum(u8) {
    ascii_letter = 0,
    ascii_digit = 1,
    whitespace = 2,
    punctuation = 3,
    high_byte = 4, // >= 128
};

/// Classify bytes in parallel using SIMD
pub fn classifyBytesSIMD(chunk: Vec32u8) @Vector(SIMD_WIDTH, u8) {
    // Create constant vectors for comparison
    const vec_a: Vec32u8 = @splat('a');
    const vec_z: Vec32u8 = @splat('z');
    const vec_A: Vec32u8 = @splat('A');
    const vec_Z: Vec32u8 = @splat('Z');
    const vec_0: Vec32u8 = @splat('0');
    const vec_9: Vec32u8 = @splat('9');
    const vec_space: Vec32u8 = @splat(' ');
    const vec_newline: Vec32u8 = @splat('\n');
    const vec_tab: Vec32u8 = @splat('\t');
    const vec_128: Vec32u8 = @splat(128);

    // Parallel comparisons (all happen at once!)
    const is_lower = (chunk >= vec_a) & (chunk <= vec_z);
    const is_upper = (chunk >= vec_A) & (chunk <= vec_Z);
    const is_digit = (chunk >= vec_0) & (chunk <= vec_9);
    const is_space = (chunk == vec_space) | (chunk == vec_newline) | (chunk == vec_tab);
    const is_high = chunk >= vec_128;

    // Combine into classification vector
    const letter_val: Vec32u8 = @splat(@intFromEnum(ByteClass.ascii_letter));
    const digit_val: Vec32u8 = @splat(@intFromEnum(ByteClass.ascii_digit));
    const space_val: Vec32u8 = @splat(@intFromEnum(ByteClass.whitespace));
    const high_val: Vec32u8 = @splat(@intFromEnum(ByteClass.high_byte));
    const none_val: Vec32u8 = @splat(255);

    const letter_mask: Vec32u8 = @select(u8, is_lower | is_upper, letter_val, none_val);
    const digit_mask: Vec32u8 = @select(u8, is_digit, digit_val, letter_mask);
    const space_mask: Vec32u8 = @select(u8, is_space, space_val, digit_mask);
    const high_mask: Vec32u8 = @select(u8, is_high, high_val, space_mask);

    return high_mask;
}

/// Find byte boundaries where tokenization might occur (SIMD accelerated)
/// Returns a bitmask where 1 = potential token boundary
pub fn findBoundariesSIMD(chunk: Vec32u8, next_chunk: Vec32u8) u32 {
    const classes = classifyBytesSIMD(chunk);
    const next_classes = classifyBytesSIMD(next_chunk);

    // Boundary occurs when class changes
    // Shift next_classes left by 1 to align with current
    var shifted: Vec32u8 = undefined;
    shifted[0] = next_classes[0];
    comptime var i = 1;
    inline while (i < SIMD_WIDTH) : (i += 1) {
        shifted[i] = classes[i - 1];
    }

    // Compare: boundary where classes differ
    const is_boundary = classes != shifted;

    // Convert boolean vector to u32 bitmask
    return @bitCast(@as(@Vector(32, u1), @intFromBool(is_boundary)));
}

/// Fast check for ASCII-only text (enables optimizations)
pub fn isAsciiSIMD(text: []const u8) bool {
    if (text.len == 0) return true;

    const vec_128: Vec32u8 = @splat(128);
    var pos: usize = 0;

    // Process 32 bytes at a time
    while (pos + SIMD_WIDTH <= text.len) : (pos += SIMD_WIDTH) {
        const chunk: Vec32u8 = text[pos..][0..SIMD_WIDTH].*;
        const is_high = chunk >= vec_128;

        // Check if any byte is >= 128
        if (@reduce(.Or, is_high)) {
            return false;
        }
    }

    // Check tail
    while (pos < text.len) : (pos += 1) {
        if (text[pos] >= 128) return false;
    }

    return true;
}

/// Count consecutive ASCII letters/digits (for greedy matching)
pub fn countAlnumSIMD(text: []const u8, start: usize) usize {
    if (start >= text.len) return 0;

    const vec_a: Vec32u8 = @splat('a');
    const vec_z: Vec32u8 = @splat('z');
    const vec_A: Vec32u8 = @splat('A');
    const vec_Z: Vec32u8 = @splat('Z');
    const vec_0: Vec32u8 = @splat('0');
    const vec_9: Vec32u8 = @splat('9');

    var pos = start;
    var count: usize = 0;

    // SIMD fast path
    while (pos + SIMD_WIDTH <= text.len) : (pos += SIMD_WIDTH) {
        const chunk: Vec32u8 = text[pos..][0..SIMD_WIDTH].*;

        const is_lower = (chunk >= vec_a) & (chunk <= vec_z);
        const is_upper = (chunk >= vec_A) & (chunk <= vec_Z);
        const is_digit = (chunk >= vec_0) & (chunk <= vec_9);
        const is_alnum = is_lower | is_upper | is_digit;

        // Count consecutive true values
        var i: usize = 0;
        while (i < SIMD_WIDTH) : (i += 1) {
            if (!is_alnum[i]) {
                return count + i;
            }
        }

        count += SIMD_WIDTH;
    }

    // Scalar tail
    while (pos < text.len) : (pos += 1) {
        const c = text[pos];
        const is_alnum = (c >= 'a' and c <= 'z') or
            (c >= 'A' and c <= 'Z') or
            (c >= '0' and c <= '9');
        if (!is_alnum) break;
        count += 1;
    }

    return count;
}

/// Find first occurrence of byte in chunk (SIMD)
pub fn findByteSIMD(chunk: Vec32u8, target: u8) ?usize {
    const vec_target: Vec32u8 = @splat(target);
    const matches = chunk == vec_target;

    // Find first match
    comptime var i = 0;
    inline while (i < SIMD_WIDTH) : (i += 1) {
        if (matches[i]) return i;
    }

    return null;
}

/// Check if text starts with pattern (SIMD accelerated)
pub fn startsWithSIMD(text: []const u8, pattern: []const u8) bool {
    if (pattern.len > text.len) return false;
    if (pattern.len == 0) return true;

    var pos: usize = 0;

    // SIMD comparison for aligned chunks
    while (pos + SIMD_WIDTH <= pattern.len and pos + SIMD_WIDTH <= text.len) : (pos += SIMD_WIDTH) {
        const text_chunk: Vec32u8 = text[pos..][0..SIMD_WIDTH].*;
        const pattern_chunk: Vec32u8 = pattern[pos..][0..SIMD_WIDTH].*;

        if (@reduce(.Or, text_chunk != pattern_chunk)) {
            return false;
        }
    }

    // Scalar tail
    while (pos < pattern.len) : (pos += 1) {
        if (text[pos] != pattern[pos]) return false;
    }

    return true;
}

/// Optimized memcmp using SIMD
pub fn equalsSIMD(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    if (a.len == 0) return true;

    var pos: usize = 0;

    // SIMD fast path
    while (pos + SIMD_WIDTH <= a.len) : (pos += SIMD_WIDTH) {
        const vec_a: Vec32u8 = a[pos..][0..SIMD_WIDTH].*;
        const vec_b: Vec32u8 = b[pos..][0..SIMD_WIDTH].*;

        if (@reduce(.Or, vec_a != vec_b)) {
            return false;
        }
    }

    // Scalar tail
    while (pos < a.len) : (pos += 1) {
        if (a[pos] != b[pos]) return false;
    }

    return true;
}

test "SIMD byte classification" {
    const text = "Hello123  \nWorld!";
    var chunk: Vec32u8 = @splat(0);
    @memcpy(chunk[0..text.len], text);

    const classes = classifyBytesSIMD(chunk);

    // Check some classifications
    try std.testing.expectEqual(@intFromEnum(ByteClass.ascii_letter), classes[0]); // 'H'
    try std.testing.expectEqual(@intFromEnum(ByteClass.ascii_digit), classes[5]); // '1'
    try std.testing.expectEqual(@intFromEnum(ByteClass.whitespace), classes[8]); // ' '
}

test "SIMD ASCII detection" {
    try std.testing.expect(isAsciiSIMD("Hello World!"));
    try std.testing.expect(!isAsciiSIMD("Hello 世界!"));
}

test "SIMD alnum counting" {
    try std.testing.expectEqual(@as(usize, 5), countAlnumSIMD("Hello World", 0));
    try std.testing.expectEqual(@as(usize, 5), countAlnumSIMD("Hello World", 6));
    try std.testing.expectEqual(@as(usize, 6), countAlnumSIMD("ABC123!", 0));
}

test "SIMD string comparison" {
    try std.testing.expect(equalsSIMD("Hello World!", "Hello World!"));
    try std.testing.expect(!equalsSIMD("Hello World!", "Hello world!"));
    try std.testing.expect(startsWithSIMD("Hello World!", "Hello"));
    try std.testing.expect(!startsWithSIMD("Hello World!", "World"));
}
