/// Trie (Prefix Tree) for Unigram substring lookup
/// Ported from HuggingFace tokenizers/src/models/unigram/trie.rs (91 lines)

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Generic Trie supporting any label type
pub fn Trie(comptime Label: type) type {
    return struct {
        const Self = @This();

        root: *Node,
        allocator: Allocator,

        pub const Node = struct {
            is_leaf: bool,
            children: std.AutoHashMap(Label, *Node),

            pub fn init(allocator: Allocator) !*Node {
                const node = try allocator.create(Node);
                node.* = Node{
                    .is_leaf = false,
                    .children = std.AutoHashMap(Label, *Node).init(allocator),
                };
                return node;
            }

            pub fn deinit(self: *Node, allocator: Allocator) void {
                var it = self.children.valueIterator();
                while (it.next()) |child| {
                    child.*.deinit(allocator);
                }
                self.children.deinit();
                allocator.destroy(self);
            }
        };

        pub fn init(allocator: Allocator) !Self {
            return Self{
                .root = try Node.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.root.deinit(self.allocator);
        }

        /// Insert a sequence into the trie
        pub fn push(self: *Self, element: []const Label) !void {
            var node = self.root;
            for (element) |label| {
                const entry = try node.children.getOrPut(label);
                if (!entry.found_existing) {
                    entry.value_ptr.* = try Node.init(self.allocator);
                }
                node = entry.value_ptr.*;
            }
            node.is_leaf = true;
        }

        /// Find all common prefixes of the input sequence
        /// Returns an iterator that yields matching prefixes
        pub fn commonPrefixSearch(self: *const Self, labels: []const Label) CommonPrefixIterator(Label) {
            return CommonPrefixIterator(Label){
                .node = self.root,
                .labels = labels,
                .index = 0,
                .prefix_len = 0,
            };
        }
    };
}

/// Iterator for common prefix search results
pub fn CommonPrefixIterator(comptime Label: type) type {
    return struct {
        const Self = @This();
        const Node = Trie(Label).Node;

        node: *const Node,
        labels: []const Label,
        index: usize,
        prefix_len: usize,

        /// Returns the length of the next matching prefix, or null if none
        pub fn next(self: *Self) ?usize {
            while (self.index < self.labels.len) {
                const label = self.labels[self.index];
                self.index += 1;
                self.prefix_len += 1;

                if (self.node.children.get(label)) |child| {
                    self.node = child;
                    if (self.node.is_leaf) {
                        return self.prefix_len;
                    }
                } else {
                    // No match found
                    return null;
                }
            }
            return null;
        }
    };
}

/// Builder for constructing a Trie
pub fn TrieBuilder(comptime Label: type) type {
    return struct {
        const Self = @This();

        trie: Trie(Label),

        pub fn init(allocator: Allocator) !Self {
            return Self{
                .trie = try Trie(Label).init(allocator),
            };
        }

        pub fn push(self: *Self, element: []const Label) !void {
            try self.trie.push(element);
        }

        pub fn build(self: Self) Trie(Label) {
            return self.trie;
        }
    };
}

// Tests
test "Trie basic operations" {
    const allocator = std.testing.allocator;

    var trie = try Trie(u8).init(allocator);
    defer trie.deinit();

    // Insert some sequences
    try trie.push("hello");
    try trie.push("help");
    try trie.push("world");

    // Search for prefixes in "hello world"
    const text = "hello world";
    var iter = trie.commonPrefixSearch(text);

    // Should find "hello" at length 5
    const len1 = iter.next();
    try std.testing.expectEqual(@as(?usize, 5), len1);

    // No more matches in "hello"
    const len2 = iter.next();
    try std.testing.expectEqual(@as(?usize, null), len2);
}

test "Trie with no matches" {
    const allocator = std.testing.allocator;

    var trie = try Trie(u8).init(allocator);
    defer trie.deinit();

    try trie.push("hello");

    var iter = trie.commonPrefixSearch("goodbye");
    try std.testing.expectEqual(@as(?usize, null), iter.next());
}
