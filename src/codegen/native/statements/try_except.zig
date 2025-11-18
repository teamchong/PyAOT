/// Try/except/finally statement code generation
const std = @import("std");
const ast = @import("../../../ast.zig");
const NativeCodegen = @import("../main.zig").NativeCodegen;
const CodegenError = @import("../main.zig").CodegenError;

pub fn genTry(self: *NativeCodegen, try_node: ast.Node.Try) CodegenError!void {
    // Wrap in block for defer scope
    try self.emitIndent();
    try self.output.appendSlice(self.allocator, "{\n");
    self.indent();

    // Generate finally as defer
    if (try_node.finalbody.len > 0) {
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "defer {\n");
        self.indent();
        for (try_node.finalbody) |stmt| {
            try self.generateStmt(stmt);
        }
        self.dedent();
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "}\n");
    }

    // Generate try block with error handling
    if (try_node.handlers.len > 0) {
        // Generate inline function for try block that can return errors
        const try_fn_name = "__pyaot_try_block";

        // Define inline helper function for try block
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "const ");
        try self.output.appendSlice(self.allocator, try_fn_name);
        try self.output.appendSlice(self.allocator, " = struct {\n");
        self.indent();
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "fn run() !void {\n");
        self.indent();

        // Try block body
        for (try_node.body) |stmt| {
            try self.generateStmt(stmt);
        }

        self.dedent();
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "}\n");
        self.dedent();
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "}.run;\n\n");

        // Call the try block and catch errors
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, try_fn_name);
        try self.output.appendSlice(self.allocator, "() catch |err| {\n");
        self.indent();

        // Generate exception handlers
        var generated_handler = false;
        for (try_node.handlers, 0..) |handler, i| {
            if (i > 0) {
                try self.emitIndent();
                try self.output.appendSlice(self.allocator, "} else ");
            } else if (handler.type != null) {
                try self.emitIndent();
            }

            if (handler.type) |exc_type| {
                // Specific exception type
                const zig_err = pythonExceptionToZigError(exc_type);
                try self.output.appendSlice(self.allocator, "if (err == error.");
                try self.output.appendSlice(self.allocator, zig_err);
                try self.output.appendSlice(self.allocator, ") {\n");
                self.indent();
                for (handler.body) |stmt| {
                    try self.generateStmt(stmt);
                }
                self.dedent();
                generated_handler = true;
            } else {
                // Bare except - catches all
                if (i > 0) {
                    try self.output.appendSlice(self.allocator, "{\n");
                } else {
                    try self.emitIndent();
                    try self.output.appendSlice(self.allocator, "{\n");
                }
                self.indent();
                // Silence unused error warning for bare except
                try self.emitIndent();
                try self.output.appendSlice(self.allocator, "_ = err;\n");
                for (handler.body) |stmt| {
                    try self.generateStmt(stmt);
                }
                self.dedent();
                try self.emitIndent();
                try self.output.appendSlice(self.allocator, "}\n");
                generated_handler = true;
            }
        }

        // Close if-else chain
        if (generated_handler and try_node.handlers[try_node.handlers.len - 1].type != null) {
            try self.emitIndent();
            try self.output.appendSlice(self.allocator, "} else {\n");
            self.indent();
            try self.emitIndent();
            try self.output.appendSlice(self.allocator, "return err;\n");
            self.dedent();
            try self.emitIndent();
            try self.output.appendSlice(self.allocator, "}\n");
        }

        self.dedent();
        try self.emitIndent();
        try self.output.appendSlice(self.allocator, "};\n");
    } else {
        // No handlers - just execute try block
        for (try_node.body) |stmt| {
            try self.generateStmt(stmt);
        }
    }

    // Close wrapper block
    self.dedent();
    try self.emitIndent();
    try self.output.appendSlice(self.allocator, "}\n");
}

/// Map Python exception names to Zig error names
fn pythonExceptionToZigError(exc_type: []const u8) []const u8 {
    if (std.mem.eql(u8, exc_type, "ZeroDivisionError")) return "ZeroDivisionError";
    if (std.mem.eql(u8, exc_type, "IndexError")) return "IndexError";
    if (std.mem.eql(u8, exc_type, "ValueError")) return "ValueError";
    if (std.mem.eql(u8, exc_type, "TypeError")) return "TypeError";
    if (std.mem.eql(u8, exc_type, "KeyError")) return "KeyError";
    return "GenericError"; // Fallback
}
