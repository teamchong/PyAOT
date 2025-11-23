const std = @import("std");
const parser = @import("src/pyregex/parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const patterns = [_][]const u8{
        "a{3}",      // Exactly 3
        "a{2,5}",    // 2 to 5
        "a{2,}",     // 2 or more
    };

    for (patterns) |pattern| {
        std.debug.print("\nPattern: '{s}'\n", .{pattern});
        
        var p = parser.Parser.init(allocator, pattern);
        var parsed = p.parse() catch |err| {
            std.debug.print("  Parse error: {}\n", .{err});
            continue;
        };
        defer parsed.deinit();
        
        std.debug.print("  AST: {s}\n", .{@tagName(parsed.root)});
        
        switch (parsed.root) {
            .repeat => |r| {
                std.debug.print("  Min: {d}\n", .{r.min});
                if (r.max) |max| {
                    std.debug.print("  Max: {d}\n", .{max});
                } else {
                    std.debug.print("  Max: unbounded\n", .{});
                }
            },
            else => {},
        }
    }
}
