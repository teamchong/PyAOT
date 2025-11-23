/// Tokenizer Trainer - Comptime algorithm selection
/// Ensures dead code elimination (unused algorithms → 0 bytes)
const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const BpeTrainer = @import("bpe_trainer.zig").BpeTrainer;
const WordPieceTrainer = @import("wordpiece_trainer.zig").WordPieceTrainer;
const UnigramTrainer = @import("unigram_trainer.zig").UnigramTrainer;

/// Available training algorithms
pub const Algorithm = enum {
    BPE,       // Byte Pair Encoding (GPT-2, GPT-3, RoBERTa)
    WordPiece, // WordPiece (BERT, DistilBERT)
    Unigram,   // Unigram Language Model (T5, ALBERT) - TODO: Full implementation
};

/// Comptime trainer selection - only selected algorithm is compiled
/// Unused algorithms compile to 0 bytes (dead code elimination)
///
/// Example usage:
/// ```zig
/// const BPE = TrainerFor(.BPE);      // Only BPE compiled
/// const WP = TrainerFor(.WordPiece); // Only WordPiece compiled
/// const UG = TrainerFor(.Unigram);   // Only Unigram compiled
/// ```
pub fn TrainerFor(comptime algorithm: Algorithm) type {
    return switch (algorithm) {
        .BPE => BpeTrainer,
        .WordPiece => WordPieceTrainer,
        .Unigram => UnigramTrainer,
    };
}

/// Default trainer (BPE)
pub const Trainer = TrainerFor(.BPE);
