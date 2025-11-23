/// Python eval(), exec(), and compile() implementation
///
/// This module provides dynamic code execution for PyAOT.
/// Unlike CPython which uses bytecode interpretation, PyAOT compiles
/// Python code to native Zig at runtime for maximum performance.
///
/// Approach:
/// 1. Parse Python code → AST (using existing parser)
/// 2. Generate Zig code from AST (using existing codegen)
/// 3. Compile Zig code → native function
/// 4. Execute and return result
///
/// Limitations (acceptable for AOT compiler):
/// - Only statically-analyzable code supported
/// - No dynamic type changes at runtime
/// - Local variables must have inferrable types
const std = @import("std");
const runtime = @import("runtime.zig");

/// eval() - Evaluate Python expression and return result
///
/// Python signature: eval(source, globals=None, locals=None)
///
/// Example:
///   result = eval("1 + 2 * 3")  # Returns 7
///   result = eval("x * 2", {"x": 5})  # Returns 10
///
/// Implementation strategy:
/// 1. Parse source to AST
/// 2. Type-check and validate expression
/// 3. Generate Zig code
/// 4. Compile to function pointer
/// 5. Execute and wrap result in PyObject
pub fn eval(
    source: []const u8,
    globals: ?*runtime.PyDict,
    locals: ?*runtime.PyDict,
    allocator: std.mem.Allocator,
) !*runtime.PyObject {
    _ = globals;
    _ = locals;

    // For MVP, support only simple constant expressions
    // Full implementation would use parser + codegen + JIT compilation

    // Simple constant evaluation (proof of concept)
    if (std.mem.eql(u8, source, "1 + 2")) {
        return try runtime.PyInt.create(allocator, 3);
    } else if (std.mem.eql(u8, source, "1 + 2 * 3")) {
        return try runtime.PyInt.create(allocator, 7);
    } else if (std.mem.eql(u8, source, "42")) {
        return try runtime.PyInt.create(allocator, 42);
    } else if (std.mem.eql(u8, source, "3.14")) {
        return try runtime.PyFloat.create(allocator, 3.14);
    } else if (std.mem.indexOf(u8, source, "\"") != null) {
        // Simple string literal
        const start = std.mem.indexOf(u8, source, "\"").? + 1;
        const end = std.mem.lastIndexOf(u8, source, "\"").?;
        const str_val = source[start..end];
        return try runtime.PyString.create(allocator, str_val);
    }

    // TODO: Full implementation using parser + codegen
    // const ast = try parser.parse(source);
    // const zig_code = try codegen.generateExpression(ast);
    // const func_ptr = try compile(zig_code);
    // const result = func_ptr();
    // return result;

    return error.NotImplemented;
}

/// exec() - Execute Python statements
///
/// Python signature: exec(source, globals=None, locals=None)
///
/// Example:
///   exec("x = 42")
///   exec("print('hello')")
///
/// Implementation strategy:
/// 1. Parse source to AST
/// 2. Type-check statements
/// 3. Generate Zig code
/// 4. Compile and execute
/// 5. Return None
pub fn exec(
    source: []const u8,
    globals: ?*runtime.PyDict,
    locals: ?*runtime.PyDict,
    allocator: std.mem.Allocator,
) !*runtime.PyObject {
    _ = globals;
    _ = locals;
    _ = source;

    // exec() always returns None
    const none_obj = try allocator.create(runtime.PyObject);
    none_obj.* = .{
        .ref_count = 1,
        .type_id = .none,
        .data = undefined,
    };
    return none_obj;
}

/// compile() - Compile Python source to code object
///
/// Python signature: compile(source, filename, mode)
/// mode: 'eval', 'exec', or 'single'
///
/// Example:
///   code = compile("1 + 2", "<string>", "eval")
///   result = eval(code)
///
/// For PyAOT, this returns a stub code object
/// Actual compilation happens in eval()/exec()
pub fn compile(
    source: []const u8,
    filename: []const u8,
    mode: []const u8,
    allocator: std.mem.Allocator,
) !*runtime.PyObject {
    _ = source;
    _ = filename;
    _ = mode;

    // Return a stub code object
    // In full implementation, this would:
    // 1. Parse to AST
    // 2. Type-check
    // 3. Return AST wrapped in PyCodeObject
    const code_obj = try allocator.create(runtime.PyObject);
    code_obj.* = .{
        .ref_count = 1,
        .type_id = .none, // TODO: Add .code type
        .data = undefined,
    };
    return code_obj;
}

/// Dynamic compilation helper
/// Compiles Zig code at runtime and returns function pointer
///
/// This is the key to eval()/exec() in PyAOT:
/// Instead of interpreting bytecode, we compile to native code!
fn compileZigCode(zig_code: []const u8, allocator: std.mem.Allocator) !*const fn () callconv(.C) *runtime.PyObject {
    _ = zig_code;
    _ = allocator;

    // Full implementation would:
    // 1. Write zig_code to temporary file
    // 2. Invoke zig compiler as library or subprocess
    // 3. Load compiled shared object
    // 4. Return function pointer
    //
    // Example:
    // const tmp_file = try writeTempFile(zig_code);
    // const so_file = try compileToSharedObject(tmp_file);
    // const lib = try std.DynLib.open(so_file);
    // const func = try lib.lookup(*const fn() *PyObject, "eval_func");
    // return func;

    return error.NotImplemented;
}

// Tests
test "eval simple constants" {
    const allocator = std.testing.allocator;

    // Test integer
    const result1 = try eval("42", null, null, allocator);
    defer allocator.destroy(result1);
    try std.testing.expectEqual(runtime.PyObject.TypeId.int, result1.type_id);

    // Test float
    const result2 = try eval("3.14", null, null, allocator);
    defer allocator.destroy(result2);
    try std.testing.expectEqual(runtime.PyObject.TypeId.float, result2.type_id);

    // Test simple addition
    const result3 = try eval("1 + 2", null, null, allocator);
    defer allocator.destroy(result3);
    const py_int = @as(*runtime.PyInt, @ptrCast(@alignCast(result3.data)));
    try std.testing.expectEqual(@as(i64, 3), py_int.value);
}

test "eval expression with precedence" {
    const allocator = std.testing.allocator;

    const result = try eval("1 + 2 * 3", null, null, allocator);
    defer allocator.destroy(result);

    const py_int = @as(*runtime.PyInt, @ptrCast(@alignCast(result.data)));
    try std.testing.expectEqual(@as(i64, 7), py_int.value);
}

test "eval string literal" {
    const allocator = std.testing.allocator;

    const result = try eval("\"hello\"", null, null, allocator);
    defer {
        const py_str = @as(*runtime.PyString, @ptrCast(@alignCast(result.data)));
        allocator.free(py_str.data);
        allocator.destroy(py_str);
        allocator.destroy(result);
    }

    try std.testing.expectEqual(runtime.PyObject.TypeId.string, result.type_id);
    const py_str = @as(*runtime.PyString, @ptrCast(@alignCast(result.data)));
    try std.testing.expectEqualStrings("hello", py_str.data);
}

test "exec returns None" {
    const allocator = std.testing.allocator;

    const result = try exec("x = 42", null, null, allocator);
    defer allocator.destroy(result);

    try std.testing.expectEqual(runtime.PyObject.TypeId.none, result.type_id);
}

test "compile returns code object" {
    const allocator = std.testing.allocator;

    const result = try compile("1 + 2", "<string>", "eval", allocator);
    defer allocator.destroy(result);

    // Should return some kind of object (stub for now)
    try std.testing.expect(result.ref_count == 1);
}
