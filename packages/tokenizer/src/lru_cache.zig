const std = @import("std");
const Allocator = std.mem.Allocator;

/// Context for byte slice hashing (for LRU cache keys)
pub const ByteSliceContext = struct {
    pub fn hash(_: ByteSliceContext, key: []const u8) u64 {
        return std.hash.Wyhash.hash(0, key);
    }

    pub fn eql(_: ByteSliceContext, a: []const u8, b: []const u8) bool {
        return std.mem.eql(u8, a, b);
    }
};

/// Simple LRU cache using HashMap + doubly-linked list
/// Evicts least recently used entries when capacity is reached
pub fn LruCache(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            key: K,
            value: V,
            prev: ?*Node = null,
            next: ?*Node = null,
        };

        map: std.HashMap(K, *Node, ByteSliceContext, std.hash_map.default_max_load_percentage),
        head: ?*Node = null, // Most recently used
        tail: ?*Node = null, // Least recently used
        capacity: usize,
        size: usize = 0,
        allocator: Allocator,

        pub fn init(allocator: Allocator, capacity: usize) Self {
            return Self{
                .map = std.HashMap(K, *Node, ByteSliceContext, std.hash_map.default_max_load_percentage).init(allocator),
                .capacity = capacity,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            // Free all nodes
            var it = self.map.valueIterator();
            while (it.next()) |node| {
                self.allocator.destroy(node.*);
            }
            self.map.deinit();
        }

        pub fn get(self: *Self, key: K) ?V {
            const node = self.map.get(key) orelse return null;

            // Move to front (most recently used)
            self.moveToFront(node);
            return node.value;
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            if (self.map.get(key)) |existing| {
                // Update existing
                existing.value = value;
                self.moveToFront(existing);
                return;
            }

            // Create new node
            const node = try self.allocator.create(Node);
            node.* = Node{
                .key = key,
                .value = value,
            };

            // Add to front
            node.next = self.head;
            if (self.head) |h| h.prev = node;
            self.head = node;
            if (self.tail == null) self.tail = node;

            try self.map.put(key, node);
            self.size += 1;

            // Evict if over capacity
            if (self.size > self.capacity) {
                self.evictLru();
            }
        }

        fn moveToFront(self: *Self, node: *Node) void {
            if (self.head == node) return; // Already at front

            // Remove from current position
            if (node.prev) |p| p.next = node.next;
            if (node.next) |n| n.prev = node.prev;
            if (self.tail == node) self.tail = node.prev;

            // Add to front
            node.prev = null;
            node.next = self.head;
            if (self.head) |h| h.prev = node;
            self.head = node;
        }

        fn evictLru(self: *Self) void {
            const lru = self.tail orelse return;

            // Remove from list
            if (lru.prev) |p| {
                p.next = null;
                self.tail = p;
            } else {
                self.head = null;
                self.tail = null;
            }

            // Remove from map
            _ = self.map.remove(lru.key);
            self.allocator.destroy(lru);
            self.size -= 1;
        }
    };
}

test "LRU cache basic operations" {
    var cache = LruCache(u32, []const u8).init(std.testing.allocator, 2);
    defer cache.deinit();

    try cache.put(1, "one");
    try cache.put(2, "two");

    try std.testing.expectEqualStrings("one", cache.get(1).?);
    try std.testing.expectEqualStrings("two", cache.get(2).?);

    // Evict oldest (1)
    try cache.put(3, "three");
    try std.testing.expect(cache.get(1) == null);
    try std.testing.expectEqualStrings("two", cache.get(2).?);
}

test "LRU cache updates existing" {
    var cache = LruCache(u32, []const u8).init(std.testing.allocator, 2);
    defer cache.deinit();

    try cache.put(1, "one");
    try cache.put(2, "two");
    try cache.put(1, "ONE"); // Update

    try std.testing.expectEqualStrings("ONE", cache.get(1).?);
    try std.testing.expectEqualStrings("two", cache.get(2).?);
}
