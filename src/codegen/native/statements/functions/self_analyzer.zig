/// Self-usage detection for method bodies
const std = @import("std");
const ast = @import("../../../../ast.zig");

/// Check if 'self' is used in method body
pub fn usesSelf(body: []ast.Node) bool {
    for (body) |stmt| {
        if (stmtUsesSelf(stmt)) return true;
    }
    return false;
}

fn stmtUsesSelf(node: ast.Node) bool {
    return switch (node) {
        .assign => |assign| {
            // Check if target is self.attr
            for (assign.targets) |target| {
                if (exprUsesSelf(target)) return true;
            }
            // Check if value uses self
            return exprUsesSelf(assign.value.*);
        },
        .expr_stmt => |expr| exprUsesSelf(expr.value.*),
        .return_stmt => |ret| if (ret.value) |val| exprUsesSelf(val.*) else false,
        .if_stmt => |if_stmt| {
            if (exprUsesSelf(if_stmt.condition.*)) return true;
            if (usesSelf(if_stmt.body)) return true;
            if (usesSelf(if_stmt.else_body)) return true;
            return false;
        },
        .while_stmt => |while_stmt| {
            if (exprUsesSelf(while_stmt.condition.*)) return true;
            return usesSelf(while_stmt.body);
        },
        .for_stmt => |for_stmt| usesSelf(for_stmt.body),
        else => false,
    };
}

fn exprUsesSelf(node: ast.Node) bool {
    return switch (node) {
        .name => |name| std.mem.eql(u8, name.id, "self"),
        .attribute => |attr| exprUsesSelf(attr.value.*),
        .call => |call| {
            if (exprUsesSelf(call.func.*)) return true;
            for (call.args) |arg| {
                if (exprUsesSelf(arg)) return true;
            }
            return false;
        },
        .binop => |binop| exprUsesSelf(binop.left.*) or exprUsesSelf(binop.right.*),
        .compare => |comp| {
            if (exprUsesSelf(comp.left.*)) return true;
            for (comp.comparators) |c| {
                if (exprUsesSelf(c)) return true;
            }
            return false;
        },
        .subscript => |sub| {
            if (exprUsesSelf(sub.value.*)) return true;
            return switch (sub.slice) {
                .index => |idx| exprUsesSelf(idx.*),
                .slice => |sl| {
                    if (sl.lower) |l| if (exprUsesSelf(l.*)) return true;
                    if (sl.upper) |u| if (exprUsesSelf(u.*)) return true;
                    if (sl.step) |s| if (exprUsesSelf(s.*)) return true;
                    return false;
                },
            };
        },
        else => false,
    };
}
