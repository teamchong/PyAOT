const std = @import("std");
const ast = @import("ast.zig");
const json = std.json;

/// Generate Zig code from AST
pub fn generate(allocator: std.mem.Allocator, ast_json: []const u8) ![]const u8 {
    // PHASE 1: Parse JSON AST from Python
    const parsed = try json.parseFromSlice(json.Value, allocator, ast_json, .{});
    defer parsed.deinit();

    // PHASE 2: Generate Zig code using ZigCodeGenerator
    var generator = try ZigCodeGenerator.init(allocator);
    defer generator.deinit();

    try generator.generate(parsed.value);

    return try generator.output.toOwnedSlice();
}

/// Expression evaluation result
const ExprResult = struct {
    code: []const u8,
    needs_try: bool,
};

/// Zig code generator - ports Python ZigCodeGenerator class
pub const ZigCodeGenerator = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    indent_level: usize,

    // State tracking (matching Python codegen)
    var_types: std.StringHashMap([]const u8),
    declared_vars: std.StringHashMap(void),
    reassigned_vars: std.StringHashMap(void),
    list_element_types: std.StringHashMap([]const u8),
    tuple_element_types: std.StringHashMap([]const u8),
    function_signatures: std.StringHashMap(json.Value),
    class_definitions: std.StringHashMap(json.Value),

    needs_runtime: bool,
    needs_allocator: bool,

    pub fn init(allocator: std.mem.Allocator) !*ZigCodeGenerator {
        const self = try allocator.create(ZigCodeGenerator);
        self.* = ZigCodeGenerator{
            .allocator = allocator,
            .output = std.ArrayList(u8).init(allocator),
            .indent_level = 0,
            .var_types = std.StringHashMap([]const u8).init(allocator),
            .declared_vars = std.StringHashMap(void).init(allocator),
            .reassigned_vars = std.StringHashMap(void).init(allocator),
            .list_element_types = std.StringHashMap([]const u8).init(allocator),
            .tuple_element_types = std.StringHashMap([]const u8).init(allocator),
            .function_signatures = std.StringHashMap(json.Value).init(allocator),
            .class_definitions = std.StringHashMap(json.Value).init(allocator),
            .needs_runtime = false,
            .needs_allocator = false,
        };
        return self;
    }

    pub fn deinit(self: *ZigCodeGenerator) void {
        self.output.deinit();
        self.var_types.deinit();
        self.declared_vars.deinit();
        self.reassigned_vars.deinit();
        self.list_element_types.deinit();
        self.tuple_element_types.deinit();
        self.function_signatures.deinit();
        self.class_definitions.deinit();
        self.allocator.destroy(self);
    }

    /// Emit a line of code with proper indentation
    pub fn emit(self: *ZigCodeGenerator, code: []const u8) !void {
        // Add indentation
        for (0..self.indent_level) |_| {
            try self.output.appendSlice("    ");
        }
        try self.output.appendSlice(code);
        try self.output.append('\n');
    }

    /// Increase indentation level
    pub fn indent(self: *ZigCodeGenerator) void {
        self.indent_level += 1;
    }

    /// Decrease indentation level
    pub fn dedent(self: *ZigCodeGenerator) void {
        if (self.indent_level > 0) {
            self.indent_level -= 1;
        }
    }

    /// Generate code from parsed AST
    pub fn generate(self: *ZigCodeGenerator, ast_node: json.Value) !void {
        // AST should be a Module with body array
        if (ast_node != .object) return error.InvalidAST;

        const module = ast_node.object;
        const body = module.get("body") orelse return error.MissingBody;

        if (body != .array) return error.InvalidBody;

        // Phase 1: Detect runtime needs and collect declarations
        for (body.array.items) |node| {
            try self.detectRuntimeNeeds(node);
            try self.collectDeclarations(node);
        }

        // Phase 2: Detect reassignments
        var assignments_seen = std.StringHashMap(void).init(self.allocator);
        defer assignments_seen.deinit();

        for (body.array.items) |node| {
            try self.detectReassignments(node, &assignments_seen);
        }

        // Reset declared_vars for code generation
        self.declared_vars.clearRetainingCapacity();

        // Phase 3: Generate code
        try self.emit("const std = @import(\"std\");");
        if (self.needs_runtime) {
            try self.emit("const runtime = @import(\"runtime.zig\");");
        }
        try self.emit("");

        try self.emit("pub fn main() !void {");
        self.indent();

        if (self.needs_allocator) {
            try self.emit("var gpa = std.heap.GeneralPurposeAllocator(.{}){};");
            try self.emit("defer _ = gpa.deinit();");
            try self.emit("const allocator = gpa.allocator();");
            try self.emit("");
        }

        for (body.array.items) |node| {
            try self.visitNode(node);
        }

        self.dedent();
        try self.emit("}");
    }

    /// Detect if node requires PyObject runtime
    fn detectRuntimeNeeds(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return;

        const node_type = node.object.get("_type") orelse return;
        if (node_type != .string) return;

        const type_name = node_type.string;

        if (std.mem.eql(u8, type_name, "Constant")) {
            const value = node.object.get("value") orelse return;
            if (value == .string) {
                self.needs_runtime = true;
                self.needs_allocator = true;
            }
        } else if (std.mem.eql(u8, type_name, "List") or
                   std.mem.eql(u8, type_name, "Dict") or
                   std.mem.eql(u8, type_name, "Tuple")) {
            self.needs_runtime = true;
            self.needs_allocator = true;
        }
    }

    /// Collect all variable declarations
    fn collectDeclarations(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return;

        const node_type = node.object.get("_type") orelse return;
        if (node_type != .string) return;

        const type_name = node_type.string;

        if (std.mem.eql(u8, type_name, "Assign")) {
            const targets = node.object.get("targets") orelse return;
            if (targets != .array) return;

            for (targets.array.items) |target| {
                if (target != .object) continue;
                const target_type = target.object.get("_type") orelse continue;
                if (target_type != .string) continue;

                if (std.mem.eql(u8, target_type.string, "Name")) {
                    const id = target.object.get("id") orelse continue;
                    if (id != .string) continue;

                    try self.declared_vars.put(id.string, {});
                }
            }
        }
    }

    /// Detect variables that are reassigned
    fn detectReassignments(self: *ZigCodeGenerator, node: json.Value, assignments_seen: *std.StringHashMap(void)) !void {
        if (node != .object) return;

        const node_type = node.object.get("_type") orelse return;
        if (node_type != .string) return;

        const type_name = node_type.string;

        if (std.mem.eql(u8, type_name, "Assign")) {
            const targets = node.object.get("targets") orelse return;
            if (targets != .array) return;

            for (targets.array.items) |target| {
                if (target != .object) continue;
                const target_type = target.object.get("_type") orelse continue;
                if (target_type != .string) continue;

                if (std.mem.eql(u8, target_type.string, "Name")) {
                    const id = target.object.get("id") orelse continue;
                    if (id != .string) continue;

                    if (assignments_seen.contains(id.string)) {
                        try self.reassigned_vars.put(id.string, {});
                    } else {
                        try assignments_seen.put(id.string, {});
                    }
                }
            }
        }
    }

    /// Visit a node and generate code
    fn visitNode(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return;

        const node_type = node.object.get("_type") orelse return;
        if (node_type != .string) return;

        const type_name = node_type.string;

        if (std.mem.eql(u8, type_name, "Assign")) {
            try self.visitAssign(node);
        } else if (std.mem.eql(u8, type_name, "Expr")) {
            const value = node.object.get("value") orelse return;
            const result = try self.visitExpr(value);

            // Free the result code if it was allocated
            if (result.code.len > 0) {
                // Expression statement - emit it
                try self.emit(result.code);
            }
        } else if (std.mem.eql(u8, type_name, "If")) {
            try self.visitIf(node);
        } else if (std.mem.eql(u8, type_name, "For")) {
            try self.visitFor(node);
        } else if (std.mem.eql(u8, type_name, "While")) {
            try self.visitWhile(node);
        } else if (std.mem.eql(u8, type_name, "FunctionDef")) {
            try self.visitFunctionDef(node);
        } else if (std.mem.eql(u8, type_name, "Return")) {
            try self.visitReturn(node);
        }
    }

    // Helper methods
    fn visitCompareOp(self: *ZigCodeGenerator, op: []const u8) ![]const u8 {
        _ = self;

        if (std.mem.eql(u8, op, "Lt")) return "<";
        if (std.mem.eql(u8, op, "LtE")) return "<=";
        if (std.mem.eql(u8, op, "Gt")) return ">";
        if (std.mem.eql(u8, op, "GtE")) return ">=";
        if (std.mem.eql(u8, op, "Eq")) return "==";
        if (std.mem.eql(u8, op, "NotEq")) return "!=";

        return "=="; // default
    }

    fn visitBinOpHelper(self: *ZigCodeGenerator, op: []const u8) ![]const u8 {
        _ = self;

        if (std.mem.eql(u8, op, "Add")) return "+";
        if (std.mem.eql(u8, op, "Sub")) return "-";
        if (std.mem.eql(u8, op, "Mult")) return "*";
        if (std.mem.eql(u8, op, "Div")) return "/";
        if (std.mem.eql(u8, op, "Mod")) return "%";
        if (std.mem.eql(u8, op, "FloorDiv")) return "//";
        if (std.mem.eql(u8, op, "Pow")) return "**";
        if (std.mem.eql(u8, op, "BitAnd")) return "&";
        if (std.mem.eql(u8, op, "BitOr")) return "|";
        if (std.mem.eql(u8, op, "BitXor")) return "^";
        if (std.mem.eql(u8, op, "LShift")) return "<<";
        if (std.mem.eql(u8, op, "RShift")) return ">>";

        return "+"; // default
    }

    // Visitor methods to be implemented
    fn visitAssign(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return error.InvalidNode;

        const targets = node.object.get("targets") orelse return error.MissingTargets;
        const value = node.object.get("value") orelse return error.MissingValue;

        if (targets != .array) return error.InvalidTargets;
        if (targets.array.items.len == 0) return error.EmptyTargets;

        // For now, handle single target
        const target = targets.array.items[0];
        if (target != .object) return error.InvalidTarget;

        const target_type = target.object.get("_type") orelse return error.MissingTargetType;
        if (target_type != .string) return error.InvalidTargetType;

        if (std.mem.eql(u8, target_type.string, "Name")) {
            const id = target.object.get("id") orelse return error.MissingId;
            if (id != .string) return error.InvalidId;

            const var_name = id.string;

            // Determine if this is first assignment or reassignment
            const is_first_assignment = !self.declared_vars.contains(var_name);
            const var_keyword = if (self.reassigned_vars.contains(var_name)) "var" else "const";

            if (is_first_assignment) {
                try self.declared_vars.put(var_name, {});
            }

            // Evaluate the value expression
            const value_result = try self.visitExpr(value);

            // Infer type from value
            if (value == .object) {
                const value_type = value.object.get("_type");
                if (value_type != null and value_type.? == .string) {
                    const vtype = value_type.?.string;

                    if (std.mem.eql(u8, vtype, "Constant")) {
                        const const_value = value.object.get("value");
                        if (const_value != null) {
                            if (const_value.? == .string) {
                                try self.var_types.put(var_name, "string");
                            } else if (const_value.? == .integer) {
                                try self.var_types.put(var_name, "int");
                            }
                        }
                    } else if (std.mem.eql(u8, vtype, "BinOp")) {
                        // Binary operation - assume int for now
                        try self.var_types.put(var_name, "int");
                    } else if (std.mem.eql(u8, vtype, "Name")) {
                        // Assigning from another variable - copy its type
                        const source_id = value.object.get("id");
                        if (source_id != null and source_id.? == .string) {
                            const source_type = self.var_types.get(source_id.?.string);
                            if (source_type) |stype| {
                                try self.var_types.put(var_name, stype);
                            }
                        }
                    } else if (std.mem.eql(u8, vtype, "List")) {
                        try self.var_types.put(var_name, "list");
                    }
                }
            }

            // Generate assignment code
            var buf = std.ArrayList(u8).init(self.allocator);

            if (is_first_assignment) {
                if (value_result.needs_try) {
                    try buf.writer().print("{s} {s} = try {s};", .{ var_keyword, var_name, value_result.code });
                    try self.emit(try buf.toOwnedSlice());

                    // Add defer for strings
                    const var_type = self.var_types.get(var_name);
                    if (var_type != null and std.mem.eql(u8, var_type.?, "string")) {
                        try self.emit("defer runtime.decref(" ++ var_name ++ ", allocator);");
                    }
                } else {
                    try buf.writer().print("{s} {s} = {s};", .{ var_keyword, var_name, value_result.code });
                    try self.emit(try buf.toOwnedSlice());
                }
            } else {
                // Reassignment
                const var_type = self.var_types.get(var_name);
                if (var_type != null and std.mem.eql(u8, var_type.?, "string")) {
                    try self.emit("runtime.decref(" ++ var_name ++ ", allocator);");
                }

                if (value_result.needs_try) {
                    try buf.writer().print("{s} = try {s};", .{ var_name, value_result.code });
                } else {
                    try buf.writer().print("{s} = {s};", .{ var_name, value_result.code });
                }
                try self.emit(try buf.toOwnedSlice());
            }
        }
    }

    fn visitExpr(self: *ZigCodeGenerator, node: json.Value) !ExprResult {
        if (node != .object) return error.InvalidNode;

        const node_type = node.object.get("_type") orelse return error.MissingType;
        if (node_type != .string) return error.InvalidType;

        const type_name = node_type.string;

        // Handle Name (variable reference)
        if (std.mem.eql(u8, type_name, "Name")) {
            const id = node.object.get("id") orelse return error.MissingId;
            if (id != .string) return error.InvalidId;

            return ExprResult{
                .code = id.string,
                .needs_try = false,
            };
        }

        // Handle Constant (literals)
        if (std.mem.eql(u8, type_name, "Constant")) {
            const value = node.object.get("value") orelse return error.MissingValue;

            if (value == .string) {
                // String literal - needs runtime
                var buf = std.ArrayList(u8).init(self.allocator);
                try buf.writer().print("runtime.PyString.create(allocator, \"{s}\")", .{value.string});
                return ExprResult{
                    .code = try buf.toOwnedSlice(),
                    .needs_try = true,
                };
            } else if (value == .integer) {
                // Integer literal
                var buf = std.ArrayList(u8).init(self.allocator);
                try buf.writer().print("{d}", .{value.integer});
                return ExprResult{
                    .code = try buf.toOwnedSlice(),
                    .needs_try = false,
                };
            } else if (value == .bool) {
                return ExprResult{
                    .code = if (value.bool) "true" else "false",
                    .needs_try = false,
                };
            }

            return error.UnsupportedConstant;
        }

        // Handle BinOp (binary operations)
        if (std.mem.eql(u8, type_name, "BinOp")) {
            const left = node.object.get("left") orelse return error.MissingLeft;
            const right = node.object.get("right") orelse return error.MissingRight;
            const op = node.object.get("op") orelse return error.MissingOp;

            const left_result = try self.visitExpr(left);
            const right_result = try self.visitExpr(right);

            if (op != .object) return error.InvalidOp;
            const op_type = op.object.get("_type") orelse return error.MissingOpType;
            if (op_type != .string) return error.InvalidOpType;

            const op_str = try self.visitBinOpHelper(op_type.string);

            var buf = std.ArrayList(u8).init(self.allocator);
            try buf.writer().print("{s} {s} {s}", .{ left_result.code, op_str, right_result.code });

            return ExprResult{
                .code = try buf.toOwnedSlice(),
                .needs_try = left_result.needs_try or right_result.needs_try,
            };
        }

        // Handle Call (function calls)
        if (std.mem.eql(u8, type_name, "Call")) {
            const func = node.object.get("func") orelse return error.MissingFunc;
            const args = node.object.get("args") orelse return error.MissingArgs;

            if (func != .object) return error.InvalidFunc;
            const func_type = func.object.get("_type") orelse return error.MissingFuncType;
            if (func_type != .string) return error.InvalidFuncType;

            if (std.mem.eql(u8, func_type.string, "Name")) {
                const func_id = func.object.get("id") orelse return error.MissingFuncId;
                if (func_id != .string) return error.InvalidFuncId;

                const func_name = func_id.string;

                // Handle print()
                if (std.mem.eql(u8, func_name, "print")) {
                    if (args != .array) return error.InvalidArgs;

                    if (args.array.items.len == 0) {
                        return ExprResult{
                            .code = "std.debug.print(\"\\n\", .{})",
                            .needs_try = false,
                        };
                    }

                    const arg = args.array.items[0];
                    const arg_result = try self.visitExpr(arg);

                    // Determine print format based on variable type
                    var buf = std.ArrayList(u8).init(self.allocator);

                    // Check if arg is a Name node to get variable type
                    if (arg == .object) {
                        const arg_type = arg.object.get("_type");
                        if (arg_type != null and arg_type.? == .string and
                            std.mem.eql(u8, arg_type.?.string, "Name"))
                        {
                            const var_name = arg.object.get("id");
                            if (var_name != null and var_name.? == .string) {
                                const var_type = self.var_types.get(var_name.?.string);
                                if (var_type) |vtype| {
                                    if (std.mem.eql(u8, vtype, "string")) {
                                        try buf.writer().print("std.debug.print(\"{{s}}\\n\", .{{runtime.PyString.getValue({s})}})", .{arg_result.code});
                                    } else {
                                        try buf.writer().print("std.debug.print(\"{{}}\\n\", .{{{s}}})", .{arg_result.code});
                                    }
                                } else {
                                    try buf.writer().print("std.debug.print(\"{{}}\\n\", .{{{s}}})", .{arg_result.code});
                                }
                            } else {
                                try buf.writer().print("std.debug.print(\"{{}}\\n\", .{{{s}}})", .{arg_result.code});
                            }
                        } else {
                            try buf.writer().print("std.debug.print(\"{{}}\\n\", .{{{s}}})", .{arg_result.code});
                        }
                    } else {
                        try buf.writer().print("std.debug.print(\"{{}}\\n\", .{{{s}}})", .{arg_result.code});
                    }

                    return ExprResult{
                        .code = try buf.toOwnedSlice(),
                        .needs_try = false,
                    };
                }

                // Handle len()
                if (std.mem.eql(u8, func_name, "len")) {
                    if (args != .array) return error.InvalidArgs;
                    if (args.array.items.len == 0) return error.MissingLenArg;

                    const arg = args.array.items[0];
                    const arg_result = try self.visitExpr(arg);

                    var buf = std.ArrayList(u8).init(self.allocator);

                    // Check variable type to determine which len() to call
                    if (arg == .object) {
                        const arg_type_node = arg.object.get("_type");
                        if (arg_type_node != null and arg_type_node.? == .string and
                            std.mem.eql(u8, arg_type_node.?.string, "Name"))
                        {
                            const var_name = arg.object.get("id");
                            if (var_name != null and var_name.? == .string) {
                                const var_type = self.var_types.get(var_name.?.string);
                                if (var_type) |vtype| {
                                    if (std.mem.eql(u8, vtype, "list")) {
                                        try buf.writer().print("runtime.PyList.len({s})", .{arg_result.code});
                                    } else if (std.mem.eql(u8, vtype, "string")) {
                                        try buf.writer().print("runtime.PyString.len({s})", .{arg_result.code});
                                    } else {
                                        try buf.writer().print("runtime.PyList.len({s})", .{arg_result.code});
                                    }
                                } else {
                                    try buf.writer().print("runtime.PyList.len({s})", .{arg_result.code});
                                }
                            } else {
                                try buf.writer().print("runtime.PyList.len({s})", .{arg_result.code});
                            }
                        } else {
                            try buf.writer().print("runtime.PyList.len({s})", .{arg_result.code});
                        }
                    } else {
                        try buf.writer().print("runtime.PyList.len({s})", .{arg_result.code});
                    }

                    return ExprResult{
                        .code = try buf.toOwnedSlice(),
                        .needs_try = false,
                    };
                }
            }

            return error.UnsupportedCall;
        }

        return error.UnsupportedExpression;
    }

    fn visitIf(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return error.InvalidNode;

        const test_node = node.object.get("test") orelse return error.MissingTest;
        const body = node.object.get("body") orelse return error.MissingBody;
        const else_branch = node.object.get("orelse");

        const test_result = try self.visitExpr(test_node);

        var buf = std.ArrayList(u8).init(self.allocator);
        try buf.writer().print("if ({s}) {{", .{test_result.code});
        try self.emit(try buf.toOwnedSlice());

        self.indent();

        if (body == .array) {
            for (body.array.items) |stmt| {
                try self.visitNode(stmt);
            }
        }

        self.dedent();

        if (else_branch != null and else_branch.? == .array and else_branch.?.array.items.len > 0) {
            try self.emit("} else {");
            self.indent();

            for (else_branch.?.array.items) |stmt| {
                try self.visitNode(stmt);
            }

            self.dedent();
        }

        try self.emit("}");
    }

    fn visitFor(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return error.InvalidNode;

        const target = node.object.get("target") orelse return error.MissingTarget;
        const iter = node.object.get("iter") orelse return error.MissingIter;
        const body = node.object.get("body") orelse return error.MissingBody;

        // Check if this is a range() call
        if (iter == .object) {
            const iter_type = iter.object.get("_type");
            if (iter_type != null and iter_type.? == .string and
                std.mem.eql(u8, iter_type.?.string, "Call"))
            {
                const func = iter.object.get("func");
                if (func != null and func.? == .object) {
                    const func_type = func.?.object.get("_type");
                    const func_id = func.?.object.get("id");

                    if (func_type != null and func_type.? == .string and
                        std.mem.eql(u8, func_type.?.string, "Name") and
                        func_id != null and func_id.? == .string and
                        std.mem.eql(u8, func_id.?.string, "range"))
                    {
                        // This is a range() loop
                        const args = iter.object.get("args");
                        if (args == null or args.? != .array) return error.InvalidRangeArgs;

                        // Get loop variable name
                        if (target != .object) return error.InvalidTarget;
                        const target_type = target.object.get("_type");
                        const target_id = target.object.get("id");

                        if (target_type == null or target_type.? != .string or
                            !std.mem.eql(u8, target_type.?.string, "Name") or
                            target_id == null or target_id.? != .string)
                        {
                            return error.InvalidLoopVariable;
                        }

                        const loop_var = target_id.?.string;
                        try self.var_types.put(loop_var, "int");

                        // Parse range arguments
                        var start: []const u8 = "0";
                        var end: []const u8 = undefined;
                        var step: []const u8 = "1";

                        if (args.?.array.items.len == 1) {
                            const end_result = try self.visitExpr(args.?.array.items[0]);
                            end = end_result.code;
                        } else if (args.?.array.items.len == 2) {
                            const start_result = try self.visitExpr(args.?.array.items[0]);
                            const end_result = try self.visitExpr(args.?.array.items[1]);
                            start = start_result.code;
                            end = end_result.code;
                        } else if (args.?.array.items.len == 3) {
                            const start_result = try self.visitExpr(args.?.array.items[0]);
                            const end_result = try self.visitExpr(args.?.array.items[1]);
                            const step_result = try self.visitExpr(args.?.array.items[2]);
                            start = start_result.code;
                            end = end_result.code;
                            step = step_result.code;
                        } else {
                            return error.InvalidRangeArgs;
                        }

                        // Check if loop variable already declared
                        const is_first_use = !self.declared_vars.contains(loop_var);

                        var buf = std.ArrayList(u8).init(self.allocator);

                        if (is_first_use) {
                            try buf.writer().print("var {s}: i64 = {s};", .{ loop_var, start });
                            try self.emit(try buf.toOwnedSlice());
                            try self.declared_vars.put(loop_var, {});
                        } else {
                            try buf.writer().print("{s} = {s};", .{ loop_var, start });
                            try self.emit(try buf.toOwnedSlice());
                        }

                        buf = std.ArrayList(u8).init(self.allocator);
                        try buf.writer().print("while ({s} < {s}) {{", .{ loop_var, end });
                        try self.emit(try buf.toOwnedSlice());

                        self.indent();

                        if (body == .array) {
                            for (body.array.items) |stmt| {
                                try self.visitNode(stmt);
                            }
                        }

                        buf = std.ArrayList(u8).init(self.allocator);
                        try buf.writer().print("{s} += {s};", .{ loop_var, step });
                        try self.emit(try buf.toOwnedSlice());

                        self.dedent();
                        try self.emit("}");

                        return;
                    }
                }
            }
        }

        return error.UnsupportedForLoop;
    }

    fn visitWhile(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return error.InvalidNode;

        const test_node = node.object.get("test") orelse return error.MissingTest;
        const body = node.object.get("body") orelse return error.MissingBody;

        const test_result = try self.visitExpr(test_node);

        var buf = std.ArrayList(u8).init(self.allocator);
        try buf.writer().print("while ({s}) {{", .{test_result.code});
        try self.emit(try buf.toOwnedSlice());

        self.indent();

        if (body == .array) {
            for (body.array.items) |stmt| {
                try self.visitNode(stmt);
            }
        }

        self.dedent();
        try self.emit("}");
    }

    fn visitFunctionDef(self: *ZigCodeGenerator, node: json.Value) !void {
        _ = self;
        _ = node;
        // TODO: Implement function definitions
        // This requires:
        // 1. Parse function name, parameters, and return type
        // 2. Generate Zig function signature
        // 3. Visit function body
        // 4. Track function in function_signatures for later calls
        return error.NotImplemented;
    }

    fn visitReturn(self: *ZigCodeGenerator, node: json.Value) !void {
        if (node != .object) return error.InvalidNode;

        const value = node.object.get("value");

        if (value == null) {
            try self.emit("return;");
        } else {
            const value_result = try self.visitExpr(value.?);
            var buf = std.ArrayList(u8).init(self.allocator);

            if (value_result.needs_try) {
                try buf.writer().print("return try {s};", .{value_result.code});
            } else {
                try buf.writer().print("return {s};", .{value_result.code});
            }

            try self.emit(try buf.toOwnedSlice());
        }
    }
};
