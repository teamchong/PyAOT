/// Collection literal code generation
/// Handles list and dict literal expressions
const std = @import("std");
const ast = @import("../../../ast.zig");
const NativeCodegen = @import("../main.zig").NativeCodegen;
const CodegenError = @import("../main.zig").CodegenError;
const expressions = @import("../expressions.zig");
const genExpr = expressions.genExpr;

/// Generate list literal or ArrayList
pub fn genList(self: *NativeCodegen, list: ast.Node.List) CodegenError!void {
    // Empty lists become ArrayList for dynamic growth
    if (list.elts.len == 0) {
        try self.output.appendSlice(self.allocator, "std.ArrayList(i64){}");
        return;
    }

    // Non-empty lists are fixed arrays
    try self.output.appendSlice(self.allocator, "&[_]");

    // Infer element type
    const elem_type = try self.type_inferrer.inferExpr(list.elts[0]);

    try elem_type.toZigType(self.allocator, &self.output);

    try self.output.appendSlice(self.allocator, "{");

    for (list.elts, 0..) |elem, i| {
        if (i > 0) try self.output.appendSlice(self.allocator, ", ");
        try genExpr(self, elem);
    }

    try self.output.appendSlice(self.allocator, "}");
}

/// Generate dict literal as StringHashMap
pub fn genDict(self: *NativeCodegen, dict: ast.Node.Dict) CodegenError!void {
    // Infer value type from first value
    const val_type = if (dict.values.len > 0)
        try self.type_inferrer.inferExpr(dict.values[0])
    else
        .unknown;

    // Generate: blk: {
    //   var map = std.StringHashMap(T).init(allocator);
    //   try map.put("key", value);
    //   break :blk map;
    // }

    try self.output.appendSlice(self.allocator, "blk: {\n");
    self.indent();
    try self.emitIndent();
    try self.output.appendSlice(self.allocator, "var map = std.StringHashMap(");
    try val_type.toZigType(self.allocator, &self.output);
    try self.output.appendSlice(self.allocator, ").init(allocator);\n");

    // Add all key-value pairs
    for (dict.keys, dict.values) |key, value| {
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "try map.put(");
        try genExpr(self, key);
        try self.output.appendSlice(self.allocator, ", ");
        try genExpr(self, value);
        try self.output.appendSlice(self.allocator, ");\n");
    }

    try self.emitIndent();
    try self.output.appendSlice(self.allocator, "break :blk map;\n");
    self.dedent();
    try self.emitIndent();
    try self.output.appendSlice(self.allocator, "}");
}
