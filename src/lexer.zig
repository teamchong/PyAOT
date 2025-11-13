const std = @import("std");

/// Token types for Python lexer
pub const TokenType = enum {
    // Keywords
    Def,
    Class,
    If,
    Elif,
    Else,
    For,
    While,
    Return,
    Break,
    Continue,
    Pass,
    Import,
    From,
    As,
    In,
    Not,
    And,
    Or,
    True,
    False,
    None,

    // Literals
    Ident,
    Number,
    String,

    // Operators
    Plus,
    Minus,
    Star,
    Slash,
    DoubleSlash,
    Percent,
    DoubleStar,
    Eq,
    EqEq,
    NotEq,
    Lt,
    LtEq,
    Gt,
    GtEq,

    // Delimiters
    LParen,
    RParen,
    LBracket,
    RBracket,
    LBrace,
    RBrace,
    Comma,
    Colon,
    Dot,
    Arrow,

    // Indentation
    Indent,
    Dedent,
    Newline,
    Eof,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
    column: usize,
};

pub const Lexer = struct {
    source: []const u8,
    current: usize,
    line: usize,
    column: usize,
    indent_stack: std.ArrayList(usize),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Lexer {
        var indent_stack = std.ArrayList(usize).init(allocator);
        try indent_stack.append(0); // Base indentation

        return Lexer{
            .source = source,
            .current = 0,
            .line = 1,
            .column = 1,
            .indent_stack = indent_stack,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.indent_stack.deinit();
    }

    pub fn tokenize(self: *Lexer) ![]Token {
        var tokens = std.ArrayList(Token).init(self.allocator);
        errdefer tokens.deinit();

        // TODO: Implement tokenization
        // This is Phase 2/3 work - lexer implementation
        // For now, this stub will be filled in by Agent 1

        try tokens.append(Token{
            .type = .Eof,
            .lexeme = "",
            .line = self.line,
            .column = self.column,
        });

        return tokens.toOwnedSlice();
    }

    fn peek(self: *Lexer) ?u8 {
        if (self.current >= self.source.len) return null;
        return self.source[self.current];
    }

    fn advance(self: *Lexer) ?u8 {
        if (self.current >= self.source.len) return null;
        const c = self.source[self.current];
        self.current += 1;
        self.column += 1;
        if (c == '\n') {
            self.line += 1;
            self.column = 1;
        }
        return c;
    }
};
