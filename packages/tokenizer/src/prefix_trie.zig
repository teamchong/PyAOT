const std = @import("std");
const Allocator = std.mem.Allocator;

/// Prefix trie for efficient string matching
/// Used to find all vocabulary tokens that match prefixes of input text
/// Replaces O(vocab_size × text_length) linear scan with O(match_length) lookup
pub const PrefixTrie = struct {
    root: *Node,
    allocator: Allocator,

    pub const Node = struct {
        /// Map from byte to child node
        children: std.AutoHashMap(u8, *Node),
        /// If this node represents a complete token, store its vocab ID
        /// null if this is an intermediate node
        value: ?usize,

        pub fn init(allocator: Allocator) !*Node {
            const node = try allocator.create(Node);
            node.* = Node{
                .children = std.AutoHashMap(u8, *Node).init(allocator),
                .value = null,
            };
            return node;
        }

        pub fn deinit(self: *Node, allocator: Allocator) void {
            var it = self.children.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.*.deinit(allocator);
            }
            self.children.deinit();
            allocator.destroy(self);
        }
    };

    /// Match result from prefix search
    pub const Match = struct {
        /// Byte length of the matched prefix
        len: usize,
        /// Vocabulary ID of the matched token
        id: usize,
    };

    /// Initialize empty trie
    pub fn init(allocator: Allocator) !PrefixTrie {
        return PrefixTrie{
            .root = try Node.init(allocator),
            .allocator = allocator,
        };
    }

    /// Free all trie nodes
    pub fn deinit(self: *PrefixTrie) void {
        self.root.deinit(self.allocator);
    }

    /// Insert a token into the trie
    /// key: the token bytes (e.g., "hello")
    /// id: the vocabulary ID for this token
    pub fn insert(self: *PrefixTrie, key: []const u8, id: usize) !void {
        var current = self.root;

        for (key) |byte| {
            const entry = try current.children.getOrPut(byte);
            if (!entry.found_existing) {
                entry.value_ptr.* = try Node.init(self.allocator);
            }
            current = entry.value_ptr.*;
        }

        // Mark this node as a terminal node with vocab ID
        current.value = id;
    }

    /// Iterator for common prefix search
    /// Finds all tokens in the trie that are prefixes of the input text
    pub const PrefixIterator = struct {
        trie: *const PrefixTrie,
        text: []const u8,
        current_node: ?*Node,
        pos: usize,
        finished: bool,

        /// Pending matches found during traversal
        matches: std.ArrayList(Match),
        match_idx: usize,

        pub fn init(trie: *const PrefixTrie, text: []const u8) !PrefixIterator {
            var it = PrefixIterator{
                .trie = trie,
                .text = text,
                .current_node = trie.root,
                .pos = 0,
                .finished = false,
                .matches = std.ArrayList(Match){},
                .match_idx = 0,
            };

            // Collect all matches eagerly
            try it.collectMatches();

            return it;
        }

        pub fn deinit(self: *PrefixIterator) void {
            self.matches.deinit(self.trie.allocator);
        }

        fn collectMatches(self: *PrefixIterator) !void {
            var current = self.current_node orelse return;
            var pos: usize = 0;

            while (pos < self.text.len) {
                const byte = self.text[pos];

                // If this node is a terminal, it's a match
                if (current.value) |id| {
                    try self.matches.append(self.trie.allocator, .{
                        .len = pos,
                        .id = id,
                    });
                }

                // Try to follow edge for this byte
                if (current.children.get(byte)) |child| {
                    current = child;
                    pos += 1;
                } else {
                    // No more matches possible
                    break;
                }
            }

            // Check if final position is a terminal
            if (current.value) |id| {
                try self.matches.append(self.trie.allocator, .{
                    .len = pos,
                    .id = id,
                });
            }
        }

        /// Get next match, or null if no more matches
        pub fn next(self: *PrefixIterator) ?Match {
            if (self.match_idx >= self.matches.items.len) {
                return null;
            }

            const match = self.matches.items[self.match_idx];
            self.match_idx += 1;
            return match;
        }
    };

    /// Find all tokens that are prefixes of the given text
    /// Returns an iterator over matches
    pub fn commonPrefixSearch(self: *const PrefixTrie, text: []const u8) !PrefixIterator {
        return try PrefixIterator.init(self, text);
    }
};

// Tests
test "PrefixTrie: basic insertion and search" {
    const allocator = std.testing.allocator;

    var trie = try PrefixTrie.init(allocator);
    defer trie.deinit();

    // Insert some tokens
    try trie.insert("hello", 1);
    try trie.insert("hell", 2);
    try trie.insert("he", 3);
    try trie.insert("world", 4);

    // Search for "hello world"
    var it = try trie.commonPrefixSearch("hello world");
    defer it.deinit();

    // Should find: "he" (len=2), "hell" (len=4), "hello" (len=5)
    var match_count: usize = 0;
    while (it.next()) |match| {
        match_count += 1;
        if (match.len == 2) {
            try std.testing.expectEqual(@as(usize, 3), match.id); // "he"
        } else if (match.len == 4) {
            try std.testing.expectEqual(@as(usize, 2), match.id); // "hell"
        } else if (match.len == 5) {
            try std.testing.expectEqual(@as(usize, 1), match.id); // "hello"
        } else {
            return error.UnexpectedMatch;
        }
    }

    try std.testing.expectEqual(@as(usize, 3), match_count);
}

test "PrefixTrie: no matches" {
    const allocator = std.testing.allocator;

    var trie = try PrefixTrie.init(allocator);
    defer trie.deinit();

    try trie.insert("hello", 1);

    var it = try trie.commonPrefixSearch("world");
    defer it.deinit();

    try std.testing.expectEqual(@as(?PrefixTrie.Match, null), it.next());
}

test "PrefixTrie: single character tokens" {
    const allocator = std.testing.allocator;

    var trie = try PrefixTrie.init(allocator);
    defer trie.deinit();

    try trie.insert("a", 1);
    try trie.insert("b", 2);
    try trie.insert("ab", 3);

    var it = try trie.commonPrefixSearch("abc");
    defer it.deinit();

    // Should find: "a" (len=1), "ab" (len=2)
    var match_count: usize = 0;
    while (it.next()) |match| {
        match_count += 1;
        if (match.len == 1) {
            try std.testing.expectEqual(@as(usize, 1), match.id);
        } else if (match.len == 2) {
            try std.testing.expectEqual(@as(usize, 3), match.id);
        }
    }

    try std.testing.expectEqual(@as(usize, 2), match_count);
}

test "PrefixTrie: UTF-8 tokens" {
    const allocator = std.testing.allocator;

    var trie = try PrefixTrie.init(allocator);
    defer trie.deinit();

    // UTF-8 tokens (byte sequences)
    try trie.insert("你", 1); // 3 bytes
    try trie.insert("你好", 2); // 6 bytes
    try trie.insert("好", 3); // 3 bytes

    var it = try trie.commonPrefixSearch("你好世界");
    defer it.deinit();

    // Should find: "你" (len=3), "你好" (len=6)
    var match_count: usize = 0;
    while (it.next()) |match| {
        match_count += 1;
        if (match.len == 3) {
            try std.testing.expectEqual(@as(usize, 1), match.id);
        } else if (match.len == 6) {
            try std.testing.expectEqual(@as(usize, 2), match.id);
        }
    }

    try std.testing.expectEqual(@as(usize, 2), match_count);
}
