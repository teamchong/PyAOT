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

    std.debug.print("\n=== Exact Count {{n}} ===\n", .{});
    try testPattern(allocator, "a{3}", "aaa", true);      // Exactly 3 a's
    try testPattern(allocator, "a{3}", "aa", false);      // Only 2 a's
    try testPattern(allocator, "a{3}", "aaaa", true);     // More than 3 (should match first 3)
    try testPattern(allocator, "a{2}", "aa", true);

    std.debug.print("\n=== Bounded Range {{n,m}} ===\n", .{});
    try testPattern(allocator, "a{2,4}", "aa", true);     // Min (2)
    try testPattern(allocator, "a{2,4}", "aaa", true);    // Middle (3)
    try testPattern(allocator, "a{2,4}", "aaaa", true);   // Max (4)
    try testPattern(allocator, "a{2,4}", "a", false);     // Below min
    try testPattern(allocator, "a{2,4}", "aaaaa", true);  // Above max (should match first 4)

    std.debug.print("\n=== Unbounded Range {{n,}} ===\n", .{});
    try testPattern(allocator, "a{2,}", "aa", true);      // Min
    try testPattern(allocator, "a{2,}", "aaa", true);     // More
    try testPattern(allocator, "a{2,}", "aaaaaaa", true); // Many
    try testPattern(allocator, "a{2,}", "a", false);      // Below min

    std.debug.print("\n=== Complex Patterns ===\n", .{});
    try testPattern(allocator, "[0-9]{3}", "123", true);       // Digit repeat
    try testPattern(allocator, "[0-9]{3}", "12", false);       // Too few
    try testPattern(allocator, "[a-z]{2,4}", "hello", true);   // Should match "hell"
}
