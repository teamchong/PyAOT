const std = @import("std");

// Forward declaration - Node is defined in core.zig
// We only use *Node (pointer), so we don't need the complete type here
const Node = @import("core.zig").Node;

/// F-string part - can be literal text, expression, or formatted expression
pub const FStringPart = union(enum) {
    literal: []const u8,
    expr: *Node,
    format_expr: struct {
        expr: *Node,
        format_spec: []const u8,
    },
};

/// F-string node - contains multiple parts
pub const FString = struct {
    parts: []FStringPart,
};
