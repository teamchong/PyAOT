/// BPE Word representation (ported from HuggingFace tokenizers word.rs)
/// Doubly-linked list of symbols for efficient merging during training

const std = @import("std");
const Allocator = std.mem.Allocator;

/// A symbol in a word - doubly-linked list node
pub const Symbol = struct {
    c: u32, // Token ID
    prev: isize, // Previous symbol index (-1 if none)
    next: isize, // Next symbol index (-1 if none)
    len: usize, // Byte length of this token

    pub fn mergeWith(self: *Symbol, other: *const Symbol, new_c: u32) void {
        self.c = new_c;
        self.len += other.len;
        self.next = other.next;
    }
};

/// Pair of token IDs
pub const Pair = struct {
    left: u32,
    right: u32,

    pub fn hash(self: Pair) u64 {
        return (@as(u64, self.left) << 32) | @as(u64, self.right);
    }
};

/// Change to a pair count (for updating during merge)
pub const Change = struct {
    pair: Pair,
    delta: i32, // +1 or -1
};

/// A word represented as a sequence of symbols (doubly-linked list)
pub const Word = struct {
    symbols: std.ArrayList(Symbol),

    pub fn init() Word {
        return Word{
            .symbols = std.ArrayList(Symbol){},
        };
    }

    pub fn initCapacity(allocator: Allocator, capacity: usize) !Word {
        var symbols = std.ArrayList(Symbol){};
        try symbols.ensureTotalCapacity(allocator, capacity);
        return Word{ .symbols = symbols };
    }

    pub fn deinit(self: *Word, allocator: Allocator) void {
        self.symbols.deinit(allocator);
    }

    /// Add a symbol to the end of the word
    pub fn add(self: *Word, allocator: Allocator, c: u32, byte_len: usize) !void {
        const len = self.symbols.items.len;
        const prev: isize = if (len > 0) @as(isize, @intCast(len - 1)) else -1;

        // Update next pointer on previous symbol
        if (len > 0) {
            self.symbols.items[len - 1].next = @intCast(len);
        }

        try self.symbols.append(allocator, Symbol{
            .c = c,
            .prev = prev,
            .next = -1,
            .len = byte_len,
        });
    }

    /// Merge all occurrences of (c1, c2) → replacement
    /// Returns list of pair count changes for updating pair_counts
    pub fn merge(
        self: *Word,
        allocator: Allocator,
        c1: u32,
        c2: u32,
        replacement: u32,
        max_length: usize,
    ) ![]Change {
        var changes = std.ArrayList(Change){};
        errdefer changes.deinit(allocator);

        var i: usize = 0;
        while (i < self.symbols.items.len) : (i += 1) {
            // Check if we found the pair (c1, c2)
            if (self.symbols.items[i].c == c1 and
                i + 1 < self.symbols.items.len and
                self.symbols.items[i + 1].c == c2)
            {
                const first = self.symbols.items[i];
                const second = self.symbols.items[i + 1];

                // Create merged symbol
                const new_s = Symbol{
                    .c = replacement,
                    .prev = first.prev,
                    .next = second.next,
                    .len = first.len + second.len,
                };

                // Track pair count changes
                // If there's a symbol before the pair
                if (i > 0) {
                    try changes.append(allocator, Change{
                        .pair = Pair{ .left = self.symbols.items[i - 1].c, .right = first.c },
                        .delta = -1,
                    });
                    if (self.symbols.items[i - 1].len + new_s.len <= max_length) {
                        try changes.append(allocator, Change{
                            .pair = Pair{ .left = self.symbols.items[i - 1].c, .right = replacement },
                            .delta = 1,
                        });
                    }
                }

                // Insert merged symbol
                try self.symbols.insert(allocator, i, new_s);
                // Remove the original pair (now at i+1 and i+2)
                _ = self.symbols.orderedRemove(i + 1);
                _ = self.symbols.orderedRemove(i + 1);

                // If there's a symbol after the merged symbol
                if (i < self.symbols.items.len - 1) {
                    try changes.append(allocator, Change{
                        .pair = Pair{ .left = second.c, .right = self.symbols.items[i + 1].c },
                        .delta = -1,
                    });
                    if (self.symbols.items[i + 1].len + new_s.len <= max_length) {
                        try changes.append(allocator, Change{
                            .pair = Pair{ .left = replacement, .right = self.symbols.items[i + 1].c },
                            .delta = 1,
                        });
                    }
                }
            }
        }

        return changes.toOwnedSlice(allocator);
    }

    /// Get token IDs as a slice
    pub fn getChars(self: *const Word, allocator: Allocator) ![]u32 {
        var result = std.ArrayList(u32){};
        try result.ensureTotalCapacity(allocator, self.symbols.items.len);
        for (self.symbols.items) |symbol| {
            try result.append(allocator, symbol.c);
        }
        return result.toOwnedSlice(allocator);
    }
};

// Tests ported from HuggingFace word.rs
test "Word: basic merge" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Word: "hello" = ['h', 'e', 'l', 'l', 'o']
    // vocab: {'h': 0, 'e': 1, 'l': 2, 'o': 3}
    var word = Word.init();
    defer word.deinit(allocator);

    try word.add(allocator, 0, 1); // 'h'
    try word.add(allocator, 1, 1); // 'e'
    try word.add(allocator, 2, 1); // 'l'
    try word.add(allocator, 2, 1); // 'l'
    try word.add(allocator, 3, 1); // 'o'

    // Merge ('l', 'l') → 'll' (ID 4)
    const changes = try word.merge(allocator, 2, 2, 4, std.math.maxInt(usize));
    defer allocator.free(changes);

    // Word should now be: ['h', 'e', 'll', 'o']
    const chars = try word.getChars(allocator);
    defer allocator.free(chars);

    try testing.expectEqualSlices(u32, &[_]u32{ 0, 1, 4, 3 }, chars);

    // Changes should be:
    // - ('e', 'l') count -1
    // - ('e', 'll') count +1
    // - ('l', 'o') count -1
    // - ('ll', 'o') count +1
    try testing.expectEqual(@as(usize, 4), changes.len);

    try testing.expectEqual(@as(u32, 1), changes[0].pair.left); // 'e'
    try testing.expectEqual(@as(u32, 2), changes[0].pair.right); // 'l'
    try testing.expectEqual(@as(i32, -1), changes[0].delta);

    try testing.expectEqual(@as(u32, 1), changes[1].pair.left); // 'e'
    try testing.expectEqual(@as(u32, 4), changes[1].pair.right); // 'll'
    try testing.expectEqual(@as(i32, 1), changes[1].delta);

    try testing.expectEqual(@as(u32, 2), changes[2].pair.left); // 'l'
    try testing.expectEqual(@as(u32, 3), changes[2].pair.right); // 'o'
    try testing.expectEqual(@as(i32, -1), changes[2].delta);

    try testing.expectEqual(@as(u32, 4), changes[3].pair.left); // 'll'
    try testing.expectEqual(@as(u32, 3), changes[3].pair.right); // 'o'
    try testing.expectEqual(@as(i32, 1), changes[3].delta);
}

test "Word: merge with max_length" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var word = Word.init();
    defer word.deinit(allocator);

    try word.add(allocator, 0, 1); // 'h'
    try word.add(allocator, 1, 1); // 'e'
    try word.add(allocator, 2, 1); // 'l'
    try word.add(allocator, 2, 1); // 'l'
    try word.add(allocator, 3, 1); // 'o'

    // Merge with max_length = 2
    const changes = try word.merge(allocator, 2, 2, 4, 2);
    defer allocator.free(changes);

    // Word should still be: ['h', 'e', 'll', 'o']
    const chars = try word.getChars(allocator);
    defer allocator.free(chars);
    try testing.expectEqualSlices(u32, &[_]u32{ 0, 1, 4, 3 }, chars);

    // Changes should skip pairs that would exceed max_length:
    // - ('e', 'l') count -1 ✅
    // - ('e', 'll') count +1 ❌ (would be 3 bytes)
    // - ('l', 'o') count -1 ✅
    // - ('ll', 'o') count +1 ❌ (would be 3 bytes)
    try testing.expectEqual(@as(usize, 2), changes.len);

    try testing.expectEqual(@as(i32, -1), changes[0].delta);
    try testing.expectEqual(@as(i32, -1), changes[1].delta);
}
