/// Unigram Tokenizer - separate from BPE/WordPiece Tokenizer
const std = @import("std");
const Allocator = std.mem.Allocator;
const Unigram = @import("unigram_model.zig").Unigram;

pub const UnigramTokenizer = struct {
    model: Unigram,
    allocator: Allocator,

    pub fn init(model: Unigram, allocator: Allocator) UnigramTokenizer {
        return UnigramTokenizer{
            .model = model,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *UnigramTokenizer) void {
        self.model.deinit();
    }

    pub fn encode(self: *UnigramTokenizer, text: []const u8) ![]u32 {
        return self.model.encode(text, self.allocator);
    }

    pub fn decode(self: *UnigramTokenizer, ids: []const u32) ![]const u8 {
        return self.model.decode(ids, self.allocator);
    }

    pub fn saveToFile(self: *UnigramTokenizer, filename: []const u8) !void {
        _ = self;
        _ = filename;
        // TODO: Implement JSON serialization
        return error.NotImplemented;
    }
};
