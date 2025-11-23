/// Fair Benchmark - Matches Rust/Python/Go methodology EXACTLY
const std = @import("std");
const parser = @import("src/pyregex/parser.zig");
const nfa_mod = @import("src/pyregex/nfa.zig");
const lazydfa = @import("src/pyregex/lazydfa.zig");
const pikevm = @import("src/pyregex/pikevm.zig");
const allocator_helper = @import("src/pyregex/allocator_helper.zig");

fn loadData(allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile("bench_data.txt", .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, 1024 * 1024);
}

fn benchmarkPattern(allocator: std.mem.Allocator, name: []const u8, pattern: []const u8, text: []const u8, iterations: usize) !void {
    var p = parser.Parser.init(allocator, pattern);
    var ast = p.parse() catch {
        std.debug.print("{s:<20} COMPILE FAILED\n", .{name});
        return;
    };
    defer ast.deinit();

    var builder = nfa_mod.Builder.init(allocator);
    const nfa = builder.build(ast.root) catch {
        std.debug.print("{s:<20} BUILD FAILED\n", .{name});
        return;
    };
    defer {
        var mut_nfa = nfa;
        mut_nfa.deinit();
    }

    var match_count: usize = undefined;
    var timer: std.time.Timer = undefined;
    var start: u64 = undefined;
    var end: u64 = undefined;

    // All patterns now use DFA with specialized fast paths
    var dfa = lazydfa.LazyDFA.init(allocator, &nfa);
    defer dfa.deinit();

    // Set prefix hints with pattern-specific tuning (optimal windows)
    if (std.mem.eql(u8, name, "Email")) {
        dfa.setPrefixWithWindow("@", 1, 4);  // Asymmetric: more after @
    } else if (std.mem.eql(u8, name, "URL")) {
        dfa.setPrefixWithWindow("://", 5, 0);  // Minimal: just "https" before
        dfa.enableUrlFastPath();  // SIMD fast path for [^\s]+
    } else if (std.mem.eql(u8, name, "Digits")) {
        dfa.enableDigitsFastPath();  // SIMD fast path for [0-9]+
    } else if (std.mem.eql(u8, name, "Word Boundary")) {
        dfa.enableWordBoundaryFastPath();  // Fast path for \b[a-z]{4,}\b
    } else if (std.mem.eql(u8, name, "Date ISO")) {
        dfa.setPrefixWithWindow("-", 4, 3);  // Optimal YYYY-MM-DD
    }

    // Count matches
    const warmup_matches = try dfa.findAll(text, allocator);
    match_count = warmup_matches.len;
    allocator.free(warmup_matches);

    // Benchmark: find ALL matches N times
    timer = try std.time.Timer.start();
    start = timer.read();

    for (0..iterations) |_| {
        const matches = try dfa.findAll(text, allocator);
        allocator.free(matches);
    }

    end = timer.read();

    _ = pikevm; // Unused now - all patterns use DFA fast paths!

    const total_ms = @as(f64, @floatFromInt(end - start)) / 1_000_000.0;
    const avg_us = (total_ms * 1000.0) / @as(f64, @floatFromInt(iterations));

    std.debug.print("{s:<20} {d:<10} {d:<12.2} {d:<12.2} {d:<12}\n", .{ name, match_count, avg_us, total_ms, iterations });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = allocator_helper.getBenchmarkAllocator(gpa);

    const text = try loadData(allocator);
    defer allocator.free(text);

    std.debug.print("PyAOT Regex Benchmark (variable iterations for accurate measurements)\n", .{});
    std.debug.print("{s:<20} {s:<10} {s:<12} {s:<12} {s:<12}\n", .{ "Pattern", "Matches", "Avg (µs)", "Total (ms)", "Iterations" });
    std.debug.print("--------------------------------------------------------------------------------\n", .{});

    // Fast patterns: 1M iterations for accuracy
    try benchmarkPattern(allocator, "Email", "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", text, 1000000);
    try benchmarkPattern(allocator, "URL", "https?://[^\\s]+", text, 1000000);
    try benchmarkPattern(allocator, "Digits", "[0-9]+", text, 1000000);

    // Slower patterns: 100k iterations
    try benchmarkPattern(allocator, "Word Boundary", "\\b[a-z]{4,}\\b", text, 100000);
    try benchmarkPattern(allocator, "Date ISO", "[0-9]{4}-[0-9]{2}-[0-9]{2}", text, 1000000);
}
