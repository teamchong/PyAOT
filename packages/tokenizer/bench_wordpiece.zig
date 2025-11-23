const std = @import("std");
const WordPiece = @import("src/wordpiece.zig").WordPiece;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Larger corpus - 20x more training data
    var corpus = std.ArrayList([]const u8){};
    defer corpus.deinit(allocator);

    // Add repeated sentences 20x
    const base_texts = [_][]const u8{
        "playing playing playing",
        "player player player",  
        "play play play",
        "hello world hello",
        "testing tokenizer testing",
    };

    var i: usize = 0;
    while (i < 20) : (i += 1) {
        for (base_texts) |text| {
            try corpus.append(allocator, text);
        }
    }

    std.debug.print("Training WordPiece on {} sentences...\n", .{corpus.items.len});

    var timer = try std.time.Timer.start();
    
    var wp = WordPiece.init(allocator, .{ .vocab_size = 5000, .min_frequency = 1 });
    defer wp.deinit();

    try wp.train(corpus.items);

    const elapsed = timer.read();
    const ms = @as(f64, @floatFromInt(elapsed)) / 1_000_000.0;

    std.debug.print("Training complete in {d:.2}ms\n", .{ms});
    std.debug.print("Final vocab size: {}\n", .{wp.vocab.count()});

    // Test encoding
    const test_word = "playing";
    const ids = try wp.encode(test_word);
    defer allocator.free(ids);

    std.debug.print("Encode '{s}' -> {} tokens\n", .{ test_word, ids.len });
}
