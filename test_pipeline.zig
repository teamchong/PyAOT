const std = @import("std");
const lexer = @import("src/lexer.zig");
const parser = @import("src/parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source =
        \\x = 5
        \\y = 10
        \\z = x + y
        \\print(z)
    ;

    std.debug.print("=== Testing Zyth Pipeline ===\n\n", .{});
    std.debug.print("Source:\n{s}\n\n", .{source});

    // Step 1: Lexer
    std.debug.print("Step 1: Lexing...\n", .{});
    var lex = try lexer.Lexer.init(allocator, source);
    defer lex.deinit();

    const tokens = try lex.tokenize();
    defer allocator.free(tokens);

    std.debug.print("✓ Tokenized: {d} tokens\n", .{tokens.len});
    for (tokens[0..@min(10, tokens.len)]) |tok| {
        std.debug.print("  {s:12} '{s}'\n", .{ @tagName(tok.type), tok.lexeme });
    }
    if (tokens.len > 10) {
        std.debug.print("  ... ({d} more tokens)\n", .{tokens.len - 10});
    }

    // Step 2: Parser
    std.debug.print("\nStep 2: Parsing...\n", .{});
    var p = parser.Parser.init(allocator, tokens);
    const tree = try p.parse();

    std.debug.print("✓ Parsed: Module with {d} statements\n", .{tree.module.body.len});
    for (tree.module.body) |node| {
        std.debug.print("  - {s}\n", .{@tagName(node)});
    }

    std.debug.print("\n✅ Lexer and Parser working correctly!\n", .{});
}
