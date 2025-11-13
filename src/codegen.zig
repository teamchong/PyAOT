const std = @import("std");
const ast = @import("ast.zig");

/// Generate Zig code from AST
pub fn generate(allocator: std.mem.Allocator, ast_json: []const u8) ![]const u8 {
    // PHASE 1: Parse JSON AST from Python
    // TODO: Parse JSON and convert to our AST type
    _ = ast_json;

    // PHASE 2/3: Port Python codegen logic to Zig
    // This is Agent 3's task - port packages/core/codegen/generator.py to Zig

    // For now, bridge to Python
    return bridgeToPythonCodegen(allocator, ast_json);
}

// TEMPORARY: Bridge to Python codegen
fn bridgeToPythonCodegen(allocator: std.mem.Allocator, ast_json: []const u8) ![]const u8 {
    // Write AST JSON to temp file
    const tmp_file = "/tmp/zyth_ast.json";
    try std.fs.cwd().writeFile(.{
        .sub_path = tmp_file,
        .data = ast_json,
    });

    // Call Python codegen
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "python",
            "-c",
            \\import json, sys
            \\# Load AST JSON and generate Zig code
            \\# For now, just use existing Python codegen
            \\from core.compiler import compile_file
            \\# TODO: Call Python codegen with AST
            \\print("// Generated Zig code placeholder")
            ,
        },
    });

    if (result.term.Exited != 0) {
        std.debug.print("Python codegen failed:\n{s}\n", .{result.stderr});
        return error.CodegenFailed;
    }

    return result.stdout;
}

/// Context for code generation
const CodegenContext = struct {
    output: std.ArrayList(u8),
    indent_level: usize,
    var_types: std.StringHashMap([]const u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) CodegenContext {
        return CodegenContext{
            .output = std.ArrayList(u8).init(allocator),
            .indent_level = 0,
            .var_types = std.StringHashMap([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *CodegenContext) void {
        self.output.deinit();
        self.var_types.deinit();
    }

    pub fn emit(self: *CodegenContext, code: []const u8) !void {
        // Add indentation
        for (0..self.indent_level) |_| {
            try self.output.appendSlice("    ");
        }
        try self.output.appendSlice(code);
        try self.output.append('\n');
    }

    pub fn indent(self: *CodegenContext) void {
        self.indent_level += 1;
    }

    pub fn dedent(self: *CodegenContext) void {
        if (self.indent_level > 0) {
            self.indent_level -= 1;
        }
    }
};

/// Generate code for a node (to be implemented by Agent 3)
fn visitNode(ctx: *CodegenContext, node: ast.Node) !void {
    _ = ctx;
    _ = node;
    // TODO: Implement node visitors
    // This mirrors the Python visit_* methods in generator.py
    return error.NotImplemented;
}
