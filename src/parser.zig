const std = @import("std");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

pub const Parser = struct {
    tokens: []const lexer.Token,
    current: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, tokens: []const lexer.Token) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
            .allocator = allocator,
        };
    }

    pub fn parse(self: *Parser) !ast.Node {
        // TODO: Implement parser
        // This is Phase 2/3 work - parser implementation
        // For now, this stub will be filled in by Agent 2

        _ = self;
        return error.NotImplemented;
    }

    fn peek(self: *Parser) ?lexer.Token {
        if (self.current >= self.tokens.len) return null;
        return self.tokens[self.current];
    }

    fn advance(self: *Parser) ?lexer.Token {
        if (self.current >= self.tokens.len) return null;
        const tok = self.tokens[self.current];
        self.current += 1;
        return tok;
    }

    fn expect(self: *Parser, token_type: lexer.TokenType) !lexer.Token {
        const tok = self.peek() orelse return error.UnexpectedEof;
        if (tok.type != token_type) return error.UnexpectedToken;
        return self.advance().?;
    }
};
