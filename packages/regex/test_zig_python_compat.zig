const std = @import("std");
const Regex = @import("src/pyregex/regex.zig").Regex;

const TestCase = struct {
    name: []const u8,
    pattern: []const u8,
    text: []const u8,
    should_match: bool,
    expected_span: ?struct { start: usize, end: usize } = null,
};

const tests = [_]TestCase{
    // Literals
    .{ .name = "literal: hello", .pattern = "hello", .text = "hello", .should_match = true, .expected_span = .{ .start = 0, .end = 5 } },
    .{ .name = "literal: world", .pattern = "world", .text = "hello world", .should_match = true, .expected_span = .{ .start = 6, .end = 11 } },
    .{ .name = "literal: test", .pattern = "test", .text = "this is a test", .should_match = true, .expected_span = .{ .start = 10, .end = 14 } },
    
    // Dot
    .{ .name = "dot: a.c", .pattern = "a.c", .text = "abc", .should_match = true, .expected_span = .{ .start = 0, .end = 3 } },
    .{ .name = "dot: .", .pattern = ".", .text = "x", .should_match = true, .expected_span = .{ .start = 0, .end = 1 } },
    
    // Quantifiers
    .{ .name = "star: a*", .pattern = "a*", .text = "aaa", .should_match = true, .expected_span = .{ .start = 0, .end = 3 } },
    .{ .name = "plus: a+", .pattern = "a+", .text = "aaa", .should_match = true, .expected_span = .{ .start = 0, .end = 3 } },
    .{ .name = "question: ab?c", .pattern = "ab?c", .text = "ac", .should_match = true, .expected_span = .{ .start = 0, .end = 2 } },
    
    // Alternation
    .{ .name = "alt: cat|dog", .pattern = "cat|dog", .text = "I have a cat", .should_match = true, .expected_span = .{ .start = 9, .end = 12 } },
    
    // Empty matches
    .{ .name = "empty: a*", .pattern = "a*", .text = "", .should_match = true, .expected_span = .{ .start = 0, .end = 0 } },
    
    // Character classes (not yet implemented)
    .{ .name = "digit: \\d", .pattern = "\\d", .text = "a1b", .should_match = true, .expected_span = .{ .start = 1, .end = 2 } },
    .{ .name = "word: \\w+", .pattern = "\\w+", .text = "hello", .should_match = true, .expected_span = .{ .start = 0, .end = 5 } },
    .{ .name = "whitespace: \\s", .pattern = "\\s", .text = "a b", .should_match = true, .expected_span = .{ .start = 1, .end = 2 } },
    
    // Anchors (not yet implemented)
    .{ .name = "anchor: ^hello", .pattern = "^hello", .text = "hello world", .should_match = true, .expected_span = .{ .start = 0, .end = 5 } },
    .{ .name = "anchor: world$", .pattern = "world$", .text = "hello world", .should_match = true, .expected_span = .{ .start = 6, .end = 11 } },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var passed: usize = 0;
    var failed: usize = 0;
    var skipped: usize = 0;

    std.debug.print("\n╔══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║  PyRegex vs Python Compatibility Test Suite                ║\n", .{});
    std.debug.print("╚══════════════════════════════════════════════════════════════╝\n\n", .{});

    for (tests) |test_case| {
        const result = testOne(allocator, test_case) catch |err| {
            std.debug.print("❌ {s}: ERROR {}\n", .{ test_case.name, err });
            skipped += 1;
            continue;
        };

        if (result) {
            std.debug.print("✅ {s}\n", .{test_case.name});
            passed += 1;
        } else {
            std.debug.print("❌ {s}\n", .{test_case.name});
            failed += 1;
        }
    }

    std.debug.print("\n╔══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║  Results: {d} passed, {d} failed, {d} skipped / {d} total          ║\n", .{ passed, failed, skipped, tests.len });
    std.debug.print("╚══════════════════════════════════════════════════════════════╝\n", .{});
}

fn testOne(allocator: std.mem.Allocator, test_case: TestCase) !bool {
    var regex = Regex.compile(allocator, test_case.pattern) catch {
        // Pattern not yet supported
        return error.PatternNotSupported;
    };
    defer regex.deinit();

    const result = try regex.find(test_case.text);

    if (result) |match| {
        var mut_match = match;
        defer mut_match.deinit(allocator);

        if (!test_case.should_match) {
            return false; // Unexpected match
        }

        if (test_case.expected_span) |expected| {
            if (match.span.start != expected.start or match.span.end != expected.end) {
                std.debug.print(" (expected ({d},{d}), got ({d},{d}))", .{
                    expected.start,
                    expected.end,
                    match.span.start,
                    match.span.end,
                });
                return false;
            }
        }

        return true;
    } else {
        return !test_case.should_match; // OK if we expected no match
    }
}
