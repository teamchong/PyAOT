const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const codegen = @import("codegen.zig");
const compiler = @import("compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try printUsage();
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "build") or std.mem.eql(u8, command, "run")) {
        if (args.len < 3) {
            std.debug.print("Error: Missing input file\n", .{});
            try printUsage();
            return;
        }

        const input_file = args[2];
        const output_file = if (args.len > 3) args[3] else null;

        try compileFile(allocator, input_file, output_file, command);
    } else if (std.mem.eql(u8, command, "test")) {
        // Run pytest for now (bridge to Python)
        std.debug.print("Running tests (bridge to Python)...\n", .{});
        _ = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "pytest", "-v" },
        });
    } else {
        // Default: treat first arg as file to run
        try compileFile(allocator, command, null, "run");
    }
}

fn compileFile(allocator: std.mem.Allocator, input_path: []const u8, output_path: ?[]const u8, mode: []const u8) !void {
    // Read source file
    const source = try std.fs.cwd().readFileAlloc(allocator, input_path, 10 * 1024 * 1024); // 10MB max
    defer allocator.free(source);

    // PHASE 1 BRIDGE: Use Python for AST (temporary)
    // TODO: Replace with pure Zig lexer/parser
    std.debug.print("Parsing (using Python bridge)...\n", .{});

    const ast_json = try getPythonAst(allocator, input_path);
    defer allocator.free(ast_json);

    std.debug.print("Generating Zig code...\n", .{});
    const zig_code = try codegen.generate(allocator, ast_json);
    defer allocator.free(zig_code);

    // Determine output path
    const bin_path = output_path orelse blk: {
        const basename = std.fs.path.basename(input_path);
        const name_no_ext = if (std.mem.lastIndexOf(u8, basename, ".")) |idx|
            basename[0..idx]
        else
            basename;

        // Create bin/ directory if it doesn't exist
        std.fs.cwd().makeDir("bin") catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };

        const path = try std.fmt.allocPrint(allocator, "bin/{s}", .{name_no_ext});
        break :blk path;
    };
    defer if (output_path == null) allocator.free(bin_path);

    // Compile Zig code to binary
    std.debug.print("Compiling to binary...\n", .{});
    try compiler.compileZig(allocator, zig_code, bin_path);

    std.debug.print("✓ Compiled successfully to: {s}\n", .{bin_path});

    // Run if mode is "run"
    if (std.mem.eql(u8, mode, "run")) {
        std.debug.print("\n", .{});
        _ = try std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{bin_path},
        });
    }
}

// TEMPORARY: Bridge to Python AST
fn getPythonAst(allocator: std.mem.Allocator, input_file: []const u8) ![]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            "python",
            "-c",
            try std.fmt.allocPrint(allocator,
                \\import ast, json, sys
                \\with open('{s}') as f:
                \\    tree = ast.parse(f.read())
                \\    print(json.dumps(ast.dump(tree, indent=2)))
                , .{input_file}
            ),
        },
    });

    if (result.term.Exited != 0) {
        std.debug.print("Python AST parsing failed:\n{s}\n", .{result.stderr});
        return error.PythonParseFailed;
    }

    return result.stdout;
}

fn printUsage() !void {
    std.debug.print(
        \\Usage:
        \\  zyth <file.py>              # Compile and run
        \\  zyth build <file.py>        # Compile only
        \\  zyth build <file.py> <out>  # Compile to specific path
        \\  zyth test                   # Run test suite
        \\
    , .{});
}
