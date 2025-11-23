const std = @import("std");
const Regex = @import("src/pyregex/regex.zig").Regex;

fn benchmark(allocator: std.mem.Allocator, pattern: []const u8, text: []const u8, iterations: usize) !u64 {
    var regex = try Regex.compile(allocator, pattern);
    defer regex.deinit();

    var timer = try std.time.Timer.start();
    const start = timer.read();

    for (0..iterations) |_| {
        var result = try regex.find(text);
        if (result) |*match| {
            match.deinit(allocator);
        }
    }

    const end = timer.read();
    return end - start;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const iterations: usize = 10000;

    std.debug.print("\n╔══════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║  PyRegex Performance Benchmark ({d} iterations)              ║\n", .{iterations});
    std.debug.print("╚══════════════════════════════════════════════════════════════╝\n\n", .{});

    const tests = [_]struct { pattern: []const u8, text: []const u8, name: []const u8 }{
        .{ .pattern = "hello", .text = "hello world", .name = "Simple literal" },
        .{ .pattern = "a+", .text = "aaaaaaa", .name = "Quantifier +" },
        .{ .pattern = "[a-z]+", .text = "helloworld", .name = "Character class" },
        .{ .pattern = "\\d{3}-\\d{4}", .text = "Phone: 555-1234", .name = "Phone number" },
        .{ .pattern = "\\bword\\b", .text = "a word here", .name = "Word boundary" },
        .{ .pattern = "^[a-z]+@[a-z]+\\.[a-z]+$", .text = "user@example.com", .name = "Email (anchored)" },
    };

    for (tests) |test_case| {
        const ns = try benchmark(allocator, test_case.pattern, test_case.text, iterations);
        const ms = @as(f64, @floatFromInt(ns)) / 1_000_000.0;
        const per_match = ms / @as(f64, @floatFromInt(iterations));

        std.debug.print("{s:30} {d:8.2} ms ({d:.4} ms/match)\n", .{
            test_case.name,
            ms,
            per_match,
        });
    }

    std.debug.print("\n", .{});
}
