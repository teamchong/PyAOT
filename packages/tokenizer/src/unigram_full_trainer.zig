/// Unigram Trainer - EM algorithm for training Unigram Language Model
/// Implements Expectation-Maximization with vocabulary pruning
/// Simplified port from HuggingFace tokenizers/src/models/unigram/trainer.rs

const std = @import("std");
const Allocator = std.mem.Allocator;
const Unigram = @import("unigram_model.zig").Unigram;
const VocabEntry = @import("unigram_model.zig").VocabEntry;
const Lattice = @import("unigram_lattice.zig").Lattice;
const Tokenizer = @import("tokenizer.zig").Tokenizer;

/// Digamma function (derivative of log gamma) for Bayesian EM
fn digamma(mut x: f64) f64 {
    var result: f64 = 0.0;
    while (x < 7.0) {
        result -= 1.0 / x;
        x += 1.0;
    }
    x -= 0.5;
    const xx = 1.0 / x;
    const xx2 = xx * xx;
    const xx4 = xx2 * xx2;
    result += @log(x) + (1.0 / 24.0) * xx2 - (7.0 / 960.0) * xx4 +
        (31.0 / 8064.0) * xx4 * xx2 - (127.0 / 30720.0) * xx4 * xx4;
    return result;
}

/// Sentence with frequency count
pub const Sentence = struct {
    text: []const u8,
    count: u32,
};

/// Piece candidate with score
pub const SentencePiece = struct {
    token: []const u8,
    score: f64,

    pub fn deinit(self: *SentencePiece, allocator: Allocator) void {
        allocator.free(self.token);
    }
};

/// Unigram trainer configuration
pub const UnigramTrainerConfig = struct {
    vocab_size: u32 = 8000,
    shrinking_factor: f64 = 0.75,
    n_sub_iterations: u32 = 2,
    max_piece_length: usize = 16,
    seed_size: usize = 1_000_000,
};

/// Unigram trainer
pub const UnigramTrainer = struct {
    config: UnigramTrainerConfig,
    allocator: Allocator,

    pub fn init(allocator: Allocator, config: UnigramTrainerConfig) UnigramTrainer {
        return UnigramTrainer{
            .config = config,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *UnigramTrainer) void {
        _ = self;
    }

    /// Generate seed vocabulary from sentences (character ngrams + frequent substrings)
    fn makeSeedPieces(self: *UnigramTrainer, sentences: []const Sentence) !std.ArrayList(SentencePiece) {
        var pieces = std.ArrayList(SentencePiece){};

        // Add UNK token
        const unk_token = try self.allocator.dupe(u8, "<UNK>");
        try pieces.append(self.allocator, SentencePiece{
            .token = unk_token,
            .score = std.math.nan(f64),
        });

        // Collect all characters
        var char_freqs = std.AutoHashMap(u21, u32).init(self.allocator);
        defer char_freqs.deinit();

        for (sentences) |sentence| {
            var iter = (try std.unicode.Utf8View.init(sentence.text)).iterator();
            while (iter.nextCodepoint()) |codepoint| {
                const entry = try char_freqs.getOrPut(codepoint);
                if (!entry.found_existing) {
                    entry.value_ptr.* = 0;
                }
                entry.value_ptr.* += sentence.count;
            }
        }

        // Add all characters to vocabulary
        var char_it = char_freqs.iterator();
        while (char_it.next()) |entry| {
            var buf: [4]u8 = undefined;
            const len = std.unicode.utf8Encode(entry.key_ptr.*, &buf) catch continue;
            const char_str = try self.allocator.dupe(u8, buf[0..len]);
            try pieces.append(self.allocator, SentencePiece{
                .token = char_str,
                .score = @floatFromInt(entry.value_ptr.*),
            });
        }

        // TODO: Add frequent bigrams/trigrams for better seed (currently simplified)
        // Full implementation would use suffix array to find frequent substrings

        return pieces;
    }

    /// E-step: Compute expected counts using forward-backward algorithm
    fn runEStep(self: *UnigramTrainer, model: *const Unigram, sentences: []const Sentence) !struct { f64, []f64 } {
        const all_sentence_freq: u32 = blk: {
            var sum: u32 = 0;
            for (sentences) |s| sum += s.count;
            break :blk sum;
        };

        var expected = try self.allocator.alloc(f64, model.vocab.len);
        @memset(expected, 0.0);

        var objs: f64 = 0.0;

        for (sentences) |sentence| {
            var lattice = try Lattice.init(self.allocator, sentence.text, model.bos_id, model.eos_id);
            defer lattice.deinit();

            try model.populateNodes(&lattice);

            const z = try lattice.populateMarginal(@floatFromInt(sentence.count), expected);
            if (std.math.isNan(z)) {
                return error.NanLikelihood;
            }

            objs -= z / @as(f64, @floatFromInt(all_sentence_freq));
        }

        return .{ objs, expected };
    }

    /// M-step: Update probabilities from expected counts
    fn runMStep(self: *UnigramTrainer, pieces: []const SentencePiece, expected: []const f64) !std.ArrayList(SentencePiece) {
        var new_pieces = std.ArrayList(SentencePiece){};

        var sum: f64 = 0.0;
        const expected_frequency_threshold = 0.5;

        for (pieces, expected, 0..) |piece, freq, i| {
            // Always keep UNK (index 0)
            if (i == 0) {
                const unk_token = try self.allocator.dupe(u8, piece.token);
                try new_pieces.append(self.allocator, SentencePiece{
                    .token = unk_token,
                    .score = std.math.nan(f64),
                });
                continue;
            }

            if (freq < expected_frequency_threshold) {
                continue;
            }

            const token = try self.allocator.dupe(u8, piece.token);
            try new_pieces.append(self.allocator, SentencePiece{
                .token = token,
                .score = freq,
            });
            sum += freq;
        }

        // Bayesian EM: Use digamma for sparse prior
        const logsum = digamma(sum);
        for (new_pieces.items[1..]) |*piece| {  // Skip UNK at index 0
            piece.score = digamma(piece.score) - logsum;
        }

        return new_pieces;
    }

    /// Prune vocabulary to target size using loss-based selection
    fn pruneVocab(self: *UnigramTrainer, pieces: []const SentencePiece, target_size: usize) !std.ArrayList(SentencePiece) {
        if (pieces.len <= target_size) {
            var result = std.ArrayList(SentencePiece){};
            for (pieces) |piece| {
                const token = try self.allocator.dupe(u8, piece.token);
                try result.append(self.allocator, SentencePiece{
                    .token = token,
                    .score = piece.score,
                });
            }
            return result;
        }

        // Simplified pruning: keep highest scoring tokens
        // Full implementation would compute loss per token
        const Candidate = struct { idx: usize, score: f64 };
        var candidates = std.ArrayList(Candidate){};
        defer candidates.deinit(self.allocator);

        for (pieces[1..], 1..) |piece, i| {  // Skip UNK
            try candidates.append(self.allocator, Candidate{ .idx = i, .score = piece.score });
        }

        // Sort by score (descending)
        std.mem.sort(Candidate, candidates.items, {}, struct {
            fn lessThan(_: void, a: Candidate, b: Candidate) bool {
                return a.score > b.score;  // Descending
            }
        }.lessThan);

        var result = std.ArrayList(SentencePiece){};

        // Always add UNK first
        const unk_token = try self.allocator.dupe(u8, pieces[0].token);
        try result.append(self.allocator, SentencePiece{
            .token = unk_token,
            .score = pieces[0].score,
        });

        // Add top scoring tokens
        const n_to_keep = @min(target_size - 1, candidates.items.len);
        for (candidates.items[0..n_to_keep]) |cand| {
            const piece = pieces[cand.idx];
            const token = try self.allocator.dupe(u8, piece.token);
            try result.append(self.allocator, SentencePiece{
                .token = token,
                .score = piece.score,
            });
        }

        return result;
    }

    /// Train Unigram model using EM algorithm
    pub fn train(self: *UnigramTrainer, sentences: []const Sentence) !Unigram {
        // 1. Generate seed vocabulary
        var pieces = try self.makeSeedPieces(sentences);
        defer {
            for (pieces.items) |*piece| piece.deinit(self.allocator);
            pieces.deinit(self.allocator);
        }

        const desired_vocab_size = (self.config.vocab_size * 11) / 10;  // 1.1x target

        // 2. EM iterations
        while (pieces.items.len > desired_vocab_size) {
            // Sub-iterations of EM
            var iter: u32 = 0;
            while (iter < self.config.n_sub_iterations) : (iter += 1) {
                // Convert to VocabEntry for model
                var vocab = try self.allocator.alloc(VocabEntry, pieces.items.len);
                defer self.allocator.free(vocab);

                for (pieces.items, 0..) |piece, i| {
                    vocab[i] = VocabEntry{
                        .token = piece.token,  // Borrow, don't copy
                        .score = piece.score,
                    };
                }

                // Create temporary model
                var model = try Unigram.init(self.allocator, vocab, 0);
                defer model.deinit();

                // E-step
                const e_result = try self.runEStep(&model, sentences);
                const expected = e_result[1];
                defer self.allocator.free(expected);

                // M-step
                var new_pieces = try self.runMStep(pieces.items, expected);
                defer {
                    for (new_pieces.items) |*piece| piece.deinit(self.allocator);
                    new_pieces.deinit(self.allocator);
                }

                // Update pieces
                for (pieces.items) |*piece| piece.deinit(self.allocator);
                pieces.clearRetainingCapacity();

                for (new_pieces.items) |piece| {
                    const token = try self.allocator.dupe(u8, piece.token);
                    try pieces.append(self.allocator, SentencePiece{
                        .token = token,
                        .score = piece.score,
                    });
                }
            }

            // Prune vocabulary
            const pruned_size = @as(usize, @intFromFloat(@as(f64, @floatFromInt(pieces.items.len)) * self.config.shrinking_factor));
            const target_size = @max(desired_vocab_size, pruned_size);

            var pruned = try self.pruneVocab(pieces.items, target_size);
            defer {
                for (pruned.items) |*piece| piece.deinit(self.allocator);
                pruned.deinit(self.allocator);
            }

            // Update pieces
            for (pieces.items) |*piece| piece.deinit(self.allocator);
            pieces.clearRetainingCapacity();

            for (pruned.items) |piece| {
                const token = try self.allocator.dupe(u8, piece.token);
                try pieces.append(self.allocator, SentencePiece{
                    .token = token,
                    .score = piece.score,
                });
            }

            if (pieces.items.len <= desired_vocab_size) {
                break;
            }
        }

        // Final model
        var vocab = try self.allocator.alloc(VocabEntry, pieces.items.len);
        for (pieces.items, 0..) |piece, i| {
            vocab[i] = VocabEntry{
                .token = try self.allocator.dupe(u8, piece.token),
                .score = piece.score,
            };
        }

        return try Unigram.init(self.allocator, vocab, 0);
    }
};

test "Unigram trainer basic" {
    const allocator = std.testing.allocator;

    const sentences = [_]Sentence{
        .{ .text = "hello", .count = 10 },
        .{ .text = "world", .count = 5 },
    };

    var trainer = UnigramTrainer.init(allocator, .{ .vocab_size = 50 });
    defer trainer.deinit();

    var model = try trainer.train(&sentences);
    defer model.deinit();

    // Model should have vocabulary
    try std.testing.expect(model.vocab.len > 0);
}
