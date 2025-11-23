/// Lattice for Unigram Language Model tokenization
/// Implements Viterbi algorithm and forward-backward for EM training
/// Ported from HuggingFace tokenizers/src/models/unigram/lattice.rs (670 lines)

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Returns log(exp(x) + exp(y)) for numerical stability
/// Used in forward-backward algorithm
fn logSumExp(x: f64, y: f64, init_mode: bool) f64 {
    if (init_mode) {
        return y;
    }
    const vmin = @min(x, y);
    const vmax = @max(x, y);
    const k_minus_log_epsilon = 50.0;

    if (vmax > vmin + k_minus_log_epsilon) {
        return vmax;
    } else {
        return vmax + @log(@exp(vmin - vmax) + 1.0);
    }
}

/// A node in the lattice
pub const Node = struct {
    id: usize,           // Vocabulary ID
    node_id: usize,      // Lattice node ID
    pos: usize,          // Position in sentence (bytes)
    length: usize,       // Length in bytes
    score: f64,          // Log probability
    backtrace_score: f64, // Best path score to this node
    prev: ?*Node,        // Previous node in best path

    pub fn init(id: usize, node_id: usize, pos: usize, length: usize, score: f64) Node {
        return Node{
            .id = id,
            .node_id = node_id,
            .pos = pos,
            .length = length,
            .score = score,
            .backtrace_score = 0.0,
            .prev = null,
        };
    }
};

/// Lattice structure for Viterbi decoding and EM training
pub const Lattice = struct {
    sentence: []const u8,
    len: usize,  // Byte length
    nodes: std.ArrayList(*Node),
    begin_nodes: std.ArrayList(std.ArrayList(*Node)), // begin_nodes[pos] = nodes starting at pos
    end_nodes: std.ArrayList(std.ArrayList(*Node)),   // end_nodes[pos] = nodes ending at pos
    bos_id: usize,
    eos_id: usize,
    allocator: Allocator,

    pub fn init(allocator: Allocator, sentence: []const u8, bos_id: usize, eos_id: usize) !Lattice {
        const len = sentence.len;
        const k_reserved_node_size = 16;

        var nodes = std.ArrayList(*Node){};
        var begin_nodes = std.ArrayList(std.ArrayList(*Node)){};
        var end_nodes = std.ArrayList(std.ArrayList(*Node)){};

        // Create begin_nodes and end_nodes vectors
        var i: usize = 0;
        while (i <= len) : (i += 1) {
            var begin_list = std.ArrayList(*Node){};
            try begin_list.ensureTotalCapacity(allocator, k_reserved_node_size);
            try begin_nodes.append(allocator, begin_list);

            var end_list = std.ArrayList(*Node){};
            try end_list.ensureTotalCapacity(allocator, k_reserved_node_size);
            try end_nodes.append(allocator, end_list);
        }

        // Create BOS (beginning of sentence) node
        const bos = try allocator.create(Node);
        bos.* = Node.init(bos_id, 0, 0, 0, 0.0);
        try nodes.append(allocator, bos);
        try end_nodes.items[0].append(allocator, bos);

        // Create EOS (end of sentence) node
        const eos = try allocator.create(Node);
        eos.* = Node.init(eos_id, 1, len, 0, 0.0);
        try nodes.append(allocator, eos);
        try begin_nodes.items[len].append(allocator, eos);

        return Lattice{
            .sentence = sentence,
            .len = len,
            .nodes = nodes,
            .begin_nodes = begin_nodes,
            .end_nodes = end_nodes,
            .bos_id = bos_id,
            .eos_id = eos_id,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Lattice) void {
        // Free all nodes
        for (self.nodes.items) |node| {
            self.allocator.destroy(node);
        }
        self.nodes.deinit(self.allocator);

        // Free begin_nodes lists
        for (self.begin_nodes.items) |*list| {
            list.deinit(self.allocator);
        }
        self.begin_nodes.deinit(self.allocator);

        // Free end_nodes lists
        for (self.end_nodes.items) |*list| {
            list.deinit(self.allocator);
        }
        self.end_nodes.deinit(self.allocator);
    }

    /// Insert a token candidate into the lattice
    pub fn insert(self: *Lattice, pos: usize, length: usize, score: f64, id: usize) !void {
        const node_id = self.nodes.items.len;
        const node = try self.allocator.create(Node);
        node.* = Node.init(id, node_id, pos, length, score);

        try self.nodes.append(self.allocator, node);
        try self.begin_nodes.items[pos].append(self.allocator, node);
        try self.end_nodes.items[pos + length].append(self.allocator, node);
    }

    /// Viterbi algorithm - find the best tokenization path
    pub fn viterbi(self: *Lattice) ![]*Node {
        var result = std.ArrayList(*Node){};
        errdefer result.deinit(self.allocator);

        var pos: usize = 0;
        while (pos <= self.len) {
            if (self.begin_nodes.items[pos].items.len == 0) {
                return result.toOwnedSlice(self.allocator);
            }

            // For each node starting at pos
            for (self.begin_nodes.items[pos].items) |rnode| {
                rnode.prev = null;
                var best_score: f64 = 0.0;
                var best_node: ?*Node = null;

                // Find best predecessor (node ending at pos)
                for (self.end_nodes.items[pos].items) |lnode| {
                    const score = lnode.backtrace_score + rnode.score;
                    if (best_node == null or score > best_score) {
                        best_node = lnode;
                        best_score = score;
                    }
                }

                if (best_node) |bnode| {
                    rnode.prev = bnode;
                    rnode.backtrace_score = best_score;
                }
            }

            // Move to next character position
            if (pos < self.len) {
                const remaining = self.sentence[pos..];
                const char_len = std.unicode.utf8ByteSequenceLength(remaining[0]) catch break;
                pos += char_len;
            } else {
                break;
            }
        }

        // Backtrace from EOS to BOS
        if (self.begin_nodes.items[self.len].items.len == 0) {
            return result.toOwnedSlice(self.allocator);
        }

        const root = self.begin_nodes.items[self.len].items[0];
        var node_opt = root.prev;

        while (node_opt) |node| {
            if (node.prev == null) break;
            try result.append(self.allocator, node);
            node_opt = node.prev;
        }

        // Reverse to get forward order
        std.mem.reverse(*Node, result.items);
        return result.toOwnedSlice(self.allocator);
    }

    /// Get the token string for a node
    pub fn piece(self: *const Lattice, node: *const Node) []const u8 {
        return self.sentence[node.pos .. node.pos + node.length];
    }

    /// Get token strings for best path
    pub fn tokens(self: *Lattice, allocator: Allocator) ![][]const u8 {
        const path = try self.viterbi();
        defer allocator.free(path);

        var result = std.ArrayList([]const u8){};
        for (path) |node| {
            const token = try allocator.dupe(u8, self.piece(node));
            try result.append(allocator, token);
        }
        return result.toOwnedSlice(allocator);
    }

    /// Forward-backward algorithm for EM training (E-step)
    /// Computes expected counts for each token
    pub fn populateMarginal(self: *const Lattice, freq: f64, expected: []f64) !f64 {
        const n_nodes = self.nodes.items.len;
        var alpha = try self.allocator.alloc(f64, n_nodes);
        defer self.allocator.free(alpha);
        var beta = try self.allocator.alloc(f64, n_nodes);
        defer self.allocator.free(beta);

        @memset(alpha, 0.0);
        @memset(beta, 0.0);

        // Forward pass
        var pos: usize = 0;
        while (pos <= self.len) : (pos += 1) {
            for (self.begin_nodes.items[pos].items) |rnode| {
                for (self.end_nodes.items[pos].items, 0..) |lnode, idx| {
                    const lid = lnode.node_id;
                    const rid = rnode.node_id;
                    alpha[rid] = logSumExp(
                        alpha[rid],
                        lnode.score + alpha[lid],
                        idx == 0,
                    );
                }
            }
        }

        // Backward pass
        var rev_pos: usize = self.len + 1;
        while (rev_pos > 0) {
            rev_pos -= 1;
            for (self.end_nodes.items[rev_pos].items) |lnode| {
                for (self.begin_nodes.items[rev_pos].items, 0..) |rnode, idx| {
                    const lid = lnode.node_id;
                    const rid = rnode.node_id;
                    beta[lid] = logSumExp(
                        beta[lid],
                        rnode.score + beta[rid],
                        idx == 0,
                    );
                }
            }
        }

        // Compute expected counts
        const eos_id = self.begin_nodes.items[self.len].items[0].node_id;
        const z = alpha[eos_id];

        for (0..self.len) |i| {
            for (self.begin_nodes.items[i].items) |node| {
                const node_id = node.node_id;
                const id = node.id;
                const a = alpha[node_id];
                const b = beta[node_id];
                const total = a + node.score + b - z;
                const update = freq * @exp(total);
                expected[id] += update;
            }
        }

        return freq * z;
    }
};

// Tests
test "Lattice basic operations" {
    const allocator = std.testing.allocator;

    var lattice = try Lattice.init(allocator, "test", 0, 1);
    defer lattice.deinit();

    try std.testing.expectEqual(@as(usize, 4), lattice.len);
    try std.testing.expectEqual(@as(usize, 0), lattice.bos_id);
    try std.testing.expectEqual(@as(usize, 1), lattice.eos_id);
}

test "Lattice insert and viterbi" {
    const allocator = std.testing.allocator;

    var lattice = try Lattice.init(allocator, "ab", 0, 1);
    defer lattice.deinit();

    // Insert some token candidates
    try lattice.insert(0, 1, -1.0, 2); // "a" with score -1.0
    try lattice.insert(1, 1, -1.0, 3); // "b" with score -1.0
    try lattice.insert(0, 2, -0.5, 4); // "ab" with score -0.5 (better!)

    const path = try lattice.viterbi();
    defer allocator.free(path);

    // Should choose "ab" (single token) over "a" + "b"
    try std.testing.expectEqual(@as(usize, 1), path.len);
    try std.testing.expectEqual(@as(usize, 4), path[0].id);
}
