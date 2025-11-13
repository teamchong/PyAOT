const std = @import("std");
const lexer = @import("src/lexer.zig");
const parser = @import("src/parser.zig");
const ast = @import("src/ast.zig");

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

    std.debug.print("Source:\n{s}\n\n", .{source});

    // Test lexer
    std.debug.print("=== LEXER TEST ===\n", .{});
    var lex = try lexer.Lexer.init(allocator, source);
    defer lex.deinit();

    const tokens = try lex.tokenize();
    defer allocator.free(tokens);

    std.debug.print("Tokens ({d}):\n", .{tokens.len});
    for (tokens) |tok| {
        std.debug.print("  {s:12} '{s}' (line {d}, col {d})\n", .{
            @tagName(tok.type),
            tok.lexeme,
            tok.line,
            tok.column,
        });
    }

    // Test parser
    std.debug.print("\n=== PARSER TEST ===\n", .{});
    var p = parser.Parser.init(allocator, tokens);
    const tree = try p.parse();

    std.debug.print("AST: Module with {d} statements\n", .{tree.module.body.len});
    for (tree.module.body, 0..) |node, i| {
        std.debug.print("  [{d}] {s}\n", .{ i, @tagName(node) });
    }

    std.debug.print("\n✓ Lexer and Parser working!\n", .{});
}
