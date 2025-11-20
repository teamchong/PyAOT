const std = @import("std");
const Trainer = @import("trainer.zig").Trainer;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const TEXT_COUNT = 150_000;
    const VOCAB_SIZE = 2048;

    // Generate training data
    var texts = std.ArrayList([]const u8){};
    defer texts.deinit(allocator);

    const sample_text = "The quick brown fox jumps over the lazy dog";
    var i: usize = 0;
    while (i < TEXT_COUNT) : (i += 1) {
        try texts.append(allocator, sample_text);
    }

    // Train
    var trainer = try Trainer.init(VOCAB_SIZE, allocator);
    defer trainer.deinit();

    const start = std.time.nanoTimestamp();
    var tokenizer = try trainer.trainFromIterator(texts.items);
    defer tokenizer.deinit();
    const end = std.time.nanoTimestamp();
    const elapsed_ms = @divFloor(end - start, 1_000_000);

    std.debug.print("{d}ms\n", .{elapsed_ms});
}
