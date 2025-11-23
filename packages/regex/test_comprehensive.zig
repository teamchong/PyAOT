const std = @import("std");
const Regex = @import("src/pyregex/regex.zig").Regex;

var passed: usize = 0;
var failed: usize = 0;

fn test_pattern(allocator: std.mem.Allocator, pattern: []const u8, text: []const u8, should_match: bool) !void {
    var regex = Regex.compile(allocator, pattern) catch {
        if (should_match) {
            std.debug.print("❌ Pattern '{s}' failed to compile\n", .{pattern});
            failed += 1;
        }
        return;
    };
    defer regex.deinit();

    var result = try regex.find(text);
    const matched = result != null;
    
    if (result) |*match| {
        defer match.deinit(allocator);
    }
    
    if (matched == should_match) {
        passed += 1;
    } else {
        std.debug.print("❌ Pattern '{s}' vs '{s}' expected {s} got {s}\n", .{
            pattern, text, 
            if (should_match) "MATCH" else "NO MATCH",
            if (matched) "MATCH" else "NO MATCH"
        });
        failed += 1;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n╔══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║  PyRegex Comprehensive Feature Test                        ║\n", .{});
    std.debug.print("╚══════════════════════════════════════════════════════════════╝\n\n", .{});

    // Basic literals
    try test_pattern(allocator, "hello", "hello world", true);
    try test_pattern(allocator, "xyz", "abc", false);

    // Quantifiers
    try test_pattern(allocator, "a*", "aaa", true);
    try test_pattern(allocator, "a+", "aaa", true);
    try test_pattern(allocator, "a?", "a", true);
    try test_pattern(allocator, "a{3}", "aaa", true);
    try test_pattern(allocator, "a{2,4}", "aaa", true);
    try test_pattern(allocator, "a{2,}", "aaaaa", true);

    // Character classes
    try test_pattern(allocator, "[abc]", "b", true);
    try test_pattern(allocator, "[a-z]", "m", true);
    try test_pattern(allocator, "[^0-9]", "a", true);
    try test_pattern(allocator, "[a-zA-Z0-9]", "5", true);

    // Built-in classes
    try test_pattern(allocator, "\\d", "5", true);
    try test_pattern(allocator, "\\w", "a", true);
    try test_pattern(allocator, "\\s", " ", true);

    // Anchors
    try test_pattern(allocator, "^hello", "hello world", true);
    try test_pattern(allocator, "world$", "hello world", true);
    try test_pattern(allocator, "^hello$", "hello", true);

    // Word boundaries
    try test_pattern(allocator, "\\bword\\b", "a word here", true);
    try test_pattern(allocator, "\\bword\\b", "sword", false);

    // Alternation
    try test_pattern(allocator, "cat|dog", "dog", true);
    try test_pattern(allocator, "cat|dog", "bird", false);

    // Dot
    try test_pattern(allocator, "a.c", "abc", true);

    // Complex patterns
    try test_pattern(allocator, "[0-9]{3}-[0-9]{4}", "555-1234", true);
    try test_pattern(allocator, "\\b[A-Z][a-z]+\\b", "Hello", true);
    try test_pattern(allocator, "^[a-z]+@[a-z]+\\.[a-z]+$", "user@example.com", true);

    std.debug.print("\n╔══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║  Results: {d} passed, {d} failed / {d} total                    ║\n", .{passed, failed, passed + failed});
    std.debug.print("╚══════════════════════════════════════════════════════════════╝\n", .{});

    if (failed > 0) {
        return error.TestFailed;
    }
}
