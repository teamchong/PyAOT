const std = @import("std");
const parser = @import("src/pyregex/parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const patterns = [_][]const u8{
        "\\bword\\b",   // Word with boundaries
        "\\Bx\\B",      // Not at word boundary
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
    }
}
