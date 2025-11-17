/// Expression-level code generation
/// Handles Python expressions: constants, binary ops, calls, lists, dicts, subscripts, etc.
const std = @import("std");
const ast = @import("../../ast.zig");
const NativeCodegen = @import("main.zig").NativeCodegen;
const CodegenError = @import("main.zig").CodegenError;
const dispatch = @import("dispatch.zig");

// Import submodules
const constants = @import("expressions/constants.zig");
const operators = @import("expressions/operators.zig");
const subscript_mod = @import("expressions/subscript.zig");
const collections = @import("expressions/collections.zig");

// Re-export functions from submodules for backward compatibility
pub const genConstant = constants.genConstant;
pub const genBinOp = operators.genBinOp;
pub const genUnaryOp = operators.genUnaryOp;
pub const genCompare = operators.genCompare;
pub const genBoolOp = operators.genBoolOp;
pub const genSubscript = genSubscriptLocal;
pub const genList = collections.genList;
pub const genDict = collections.genDict;

/// Main expression dispatcher
pub fn genExpr(self: *NativeCodegen, node: ast.Node) CodegenError!void {
    switch (node) {
        .constant => |c| try constants.genConstant(self, c),
        .name => |n| try self.output.appendSlice(self.allocator, n.id),
        .binop => |b| try operators.genBinOp(self, b),
        .unaryop => |u| try operators.genUnaryOp(self, u),
        .compare => |c| try operators.genCompare(self, c),
        .boolop => |b| try operators.genBoolOp(self, b),
        .call => |c| try genCall(self, c),
        .list => |l| try collections.genList(self, l),
        .dict => |d| try collections.genDict(self, d),
        .tuple => |t| try genTuple(self, t),
        .subscript => |s| try genSubscriptLocal(self, s),
        .attribute => |a| try genAttribute(self, a),
        else => {},
    }
}

/// Generate function call - dispatches to specialized handlers or fallback
fn genCall(self: *NativeCodegen, call: ast.Node.Call) CodegenError!void {
    // Try to dispatch to specialized handler
    const dispatched = try dispatch.dispatchCall(self, call);
    if (dispatched) return;

    // Handle method calls (obj.method())
    if (call.func.* == .attribute) {
        const attr = call.func.attribute;

        // Generic method call: obj.method(args)
        try genExpr(self, attr.value.*);
        try self.output.appendSlice(self.allocator, ".");
        try self.output.appendSlice(self.allocator, attr.attr);
        try self.output.appendSlice(self.allocator, "(");

        for (call.args, 0..) |arg, i| {
            if (i > 0) try self.output.appendSlice(self.allocator, ", ");
            try genExpr(self, arg);
        }

        try self.output.appendSlice(self.allocator, ")");
        return;
    }

    // Check for class instantiation (ClassName() -> ClassName.init())
    if (call.func.* == .name) {
        const func_name = call.func.name.id;

        // If name starts with uppercase, it's a class constructor
        if (func_name.len > 0 and std.ascii.isUpper(func_name[0])) {
            // Class instantiation: Counter(10) -> Counter.init(10)
            try self.output.appendSlice(self.allocator, func_name);
            try self.output.appendSlice(self.allocator, ".init(");

            for (call.args, 0..) |arg, i| {
                if (i > 0) try self.output.appendSlice(self.allocator, ", ");
                try genExpr(self, arg);
            }

            try self.output.appendSlice(self.allocator, ")");
            return;
        }

        // Fallback: regular function call
        try self.output.appendSlice(self.allocator, func_name);
        try self.output.appendSlice(self.allocator, "(");

        for (call.args, 0..) |arg, i| {
            if (i > 0) try self.output.appendSlice(self.allocator, ", ");
            try genExpr(self, arg);
        }

        try self.output.appendSlice(self.allocator, ")");
    }
}

/// Generate tuple literal as Zig anonymous struct
fn genTuple(self: *NativeCodegen, tuple: ast.Node.Tuple) CodegenError!void {
    // Empty tuples become empty struct
    if (tuple.elts.len == 0) {
        try self.output.appendSlice(self.allocator, ".{}");
        return;
    }

    // Non-empty tuples: .{ elem1, elem2, elem3 }
    try self.output.appendSlice(self.allocator, ".{ ");

    for (tuple.elts, 0..) |elem, i| {
        if (i > 0) try self.output.appendSlice(self.allocator, ", ");
        try genExpr(self, elem);
    }

    try self.output.appendSlice(self.allocator, " }");
}

/// Generate array/dict subscript with tuple support (a[b])
/// Wraps subscript_mod.genSubscript but adds tuple indexing support
fn genSubscriptLocal(self: *NativeCodegen, subscript: ast.Node.Subscript) CodegenError!void {
    // Check if this is tuple indexing (only for index, not slice)
    if (subscript.slice == .index) {
        const value_type = try self.type_inferrer.inferExpr(subscript.value.*);

        if (value_type == .tuple) {
            // Tuple indexing: t[0] -> t.@"0"
            // Only constant indices supported for tuples
            if (subscript.slice.index.* == .constant and subscript.slice.index.constant.value == .int) {
                const index = subscript.slice.index.constant.value.int;
                try genExpr(self, subscript.value.*);
                try self.output.writer(self.allocator).print(".@\"{d}\"", .{index});
            } else {
                // Non-constant tuple index - error
                try self.output.appendSlice(self.allocator, "@compileError(\"Tuple indexing requires constant index\")");
            }
            return;
        }
    }

    // Delegate to subscript module for all other cases
    try subscript_mod.genSubscript(self, subscript);
}

/// Generate attribute access (obj.attr)
fn genAttribute(self: *NativeCodegen, attr: ast.Node.Attribute) CodegenError!void {
    // self.x -> self.x (direct translation in Zig)
    try genExpr(self, attr.value.*);
    try self.output.appendSlice(self.allocator, ".");
    try self.output.appendSlice(self.allocator, attr.attr);
}
