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
            std.debug.print("✓ MATCH at ({d}, {d})\n", .{match.span.start, match.span.end});
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

    std.debug.print("\n=== Positive Character Classes ===\n", .{});
    try testPattern(allocator, "[abc]", "a", true);
    try testPattern(allocator, "[abc]", "b", true);
    try testPattern(allocator, "[abc]", "c", true);
    try testPattern(allocator, "[abc]", "d", false);
    try testPattern(allocator, "[abc]", "xbx", true);  // Should find 'b'

    std.debug.print("\n=== Range Character Classes ===\n", .{});
    try testPattern(allocator, "[a-z]", "hello", true);
    try testPattern(allocator, "[a-z]", "x", true);
    try testPattern(allocator, "[a-z]", "A", false);
    try testPattern(allocator, "[0-9]", "5", true);
    try testPattern(allocator, "[0-9]", "abc123", true);  // Should find '1'

    std.debug.print("\n=== Multiple Ranges ===\n", .{});
    try testPattern(allocator, "[a-zA-Z]", "hello", true);
    try testPattern(allocator, "[a-zA-Z]", "WORLD", true);
    try testPattern(allocator, "[a-zA-Z]", "123", false);
    try testPattern(allocator, "[a-z0-9]", "abc123", true);

    std.debug.print("\n=== Negated Classes ===\n", .{});
    try testPattern(allocator, "[^abc]", "d", true);
    try testPattern(allocator, "[^abc]", "a", false);
    try testPattern(allocator, "[^abc]", "xyz", true);  // Should find 'x'
    try testPattern(allocator, "[^0-9]", "abc", true);  // Should find 'a'
    try testPattern(allocator, "[^0-9]", "123", false);  // No match
}
