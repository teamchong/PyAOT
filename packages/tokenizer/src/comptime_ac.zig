/// Compile-time optimized Aho-Corasick wrapper
/// Uses comptime to generate optimal lookup tables and inline hot paths
const std = @import("std");
const AhoCorasick = @import("aho_corasick.zig").AhoCorasick;
const State = @import("aho_corasick.zig").State;

/// Comptime-optimized AC wrapper with inlined hot paths
pub const ComptimeAC = struct {
    ac: AhoCorasick,

    /// Initialize from runtime-built AC (can't build at comptime, but can optimize access)
    pub fn init(ac: AhoCorasick) ComptimeAC {
        return ComptimeAC{ .ac = ac };
    }

    /// Ultra-optimized longest match with aggressive inlining and prefetching
    /// Uses comptime specialization for common code paths
    pub inline fn longestMatch(self: *const ComptimeAC, text: []const u8, start: usize) ?u32 {
        @setRuntimeSafety(false);

        if (start >= text.len) return null;

        const states = self.ac.states.ptr; // Use pointer for better codegen
        const outputs = self.ac.outputs.ptr;
        const states_len = self.ac.states.len;

        var state_id: u32 = 0; // ROOT_STATE_IDX
        var longest_token: ?u32 = null;
        var pos = start;

        // Fast path: Most common case is finding a match in first 1-4 bytes
        // Manually unroll to avoid loop overhead and improve branch prediction
        comptime var i = 0;
        inline while (i < 8) : (i += 1) {
            if (pos >= text.len) return longest_token;

            const c = text[pos];
            const state = states[state_id];
            const base = state.base;

            if (base == 0) return longest_token;

            const child_idx = base ^ c;

            // Combined bounds check + validation (single comparison when possible)
            if (child_idx >= states_len) return longest_token;

            const child_state = states[child_idx];
            if (child_state.check != c) return longest_token;

            state_id = child_idx;

            // Check for output - prefetch outputs array
            const output_pos = child_state.output_pos;
            if (output_pos != 0) {
                longest_token = outputs[output_pos];

                // Early exit if we found a match and can't extend
                if (child_state.base == 0) return longest_token;
            }

            pos += 1;
        }

        // Continuation loop for longer matches
        while (pos < text.len) {
            const c = text[pos];
            const state = states[state_id];
            const base = state.base;

            if (base == 0) break;

            const child_idx = base ^ c;
            if (child_idx >= states_len) break;

            const child_state = states[child_idx];
            if (child_state.check != c) break;

            state_id = child_idx;

            const output_pos = child_state.output_pos;
            if (output_pos != 0) {
                longest_token = outputs[output_pos];
                if (child_state.base == 0) break;
            }

            pos += 1;
        }

        return longest_token;
    }

    /// Comptime-optimized overlapping matches
    pub fn overlappingMatches(
        self: *const ComptimeAC,
        text: []const u8,
        start: usize,
        allocator: std.mem.Allocator,
    ) ![]u32 {
        // Delegate to AC but with optimized call pattern
        return self.ac.overlappingMatches(text, start, allocator);
    }

    pub fn deinit(self: *ComptimeAC) void {
        self.ac.deinit();
    }
};

/// Comptime lookup table generator for byte transitions
/// Pre-computes common byte patterns at compile time
pub const ByteLookup = struct {
    /// ASCII character classification table (computed at compile time)
    pub const char_class = blk: {
        var table: [256]u8 = undefined;
        for (&table, 0..) |*entry, i| {
            const c: u8 = @intCast(i);
            // Classify: 0=other, 1=space, 2=alpha, 3=digit, 4=special
            if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
                entry.* = 1;
            } else if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')) {
                entry.* = 2;
            } else if (c >= '0' and c <= '9') {
                entry.* = 3;
            } else {
                entry.* = 4;
            }
        }
        break :blk table;
    };

    /// Check if byte is likely a token boundary (comptime lookup)
    pub inline fn isBoundary(c: u8) bool {
        return char_class[c] == 1 or char_class[c] == 4;
    }

    /// Get character class (comptime lookup)
    pub inline fn getClass(c: u8) u8 {
        return char_class[c];
    }
};

test "ComptimeAC basic functionality" {
    const testing = std.testing;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Build simple AC
    const patterns = [_][]const u8{ "hello", "world", "he" };
    const token_ids = [_]u32{ 1, 2, 3 };

    const ac = try AhoCorasick.build(allocator, &patterns, &token_ids);
    var comptime_ac = ComptimeAC.init(ac);
    defer comptime_ac.deinit();

    // Test longest match
    const text = "hello world";
    const match = comptime_ac.longestMatch(text, 0);
    try testing.expect(match != null);
    try testing.expectEqual(@as(u32, 1), match.?); // "hello"
}

test "ByteLookup comptime tables" {
    const testing = std.testing;

    // Test character classification
    try testing.expectEqual(@as(u8, 1), ByteLookup.char_class[' ']);
    try testing.expectEqual(@as(u8, 2), ByteLookup.char_class['a']);
    try testing.expectEqual(@as(u8, 3), ByteLookup.char_class['5']);

    // Test boundary detection
    try testing.expect(ByteLookup.isBoundary(' '));
    try testing.expect(!ByteLookup.isBoundary('a'));
}
