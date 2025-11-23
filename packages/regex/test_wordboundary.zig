const std = @import("std");
const Regex = @import("src/pyregex/regex.zig").Regex;

pub fn testPattern(allocator: std.mem.Allocator, pattern: []const u8, text: []const u8, should_match: bool) !void {
    std.debug.print("Testing '{s}' against '{s}' (expect: {s})... ", .{pattern, text, if (should_match) "MATCH" else "NO MATCH"});
    
    var regex = Regex.compile(allocator, pattern) catch |err| {
        std.debug.print("COMPILE ERROR: {}\n", .{err});
        return err;
    };
    defer regex.deinit();

    const result = try regex.find(text);
    
    if (result) |match| {
        var mut_match = match;
        defer mut_match.deinit(allocator);
        
        if (should_match) {
            const matched_text = text[match.span.start..match.span.end];
            std.debug.print("✓ MATCH '{s}' at ({d}, {d})\n", .{matched_text, match.span.start, match.span.end});
        } else {
            std.debug.print("✗ UNEXPECTED MATCH at ({d}, {d})\n", .{match.span.start, match.span.end});
        }
    } else {
        if (!should_match) {
            std.debug.print("✓ NO MATCH\n", .{});
        } else {
            std.debug.print("✗ EXPECTED MATCH\n", .{});
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== Word Boundary \\b ===\n", .{});
    try testPattern(allocator, "\\bword\\b", "word", true);        // Standalone word
    try testPattern(allocator, "\\bword\\b", "a word here", true);  // Word in sentence
    try testPattern(allocator, "\\bword\\b", "sword", false);      // Part of word (start)
    try testPattern(allocator, "\\bword\\b", "wordy", false);      // Part of word (end)
    try testPattern(allocator, "\\bcat\\b", "cat dog", true);      // At start
    try testPattern(allocator, "\\bdog\\b", "cat dog", true);      // At end

    std.debug.print("\n=== Not Word Boundary \\B ===\n", .{});
    try testPattern(allocator, "\\Bx\\B", "axb", true);      // x in middle of word
    try testPattern(allocator, "\\Bx\\B", "x", false);       // x standalone
    try testPattern(allocator, "\\Bx\\B", "ax", false);      // x at end
    try testPattern(allocator, "\\Bx\\B", "xb", false);      // x at start
}
