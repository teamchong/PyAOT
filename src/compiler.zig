const std = @import("std");

/// Compile Zig source code to native binary
pub fn compileZig(allocator: std.mem.Allocator, zig_code: []const u8, output_path: []const u8) !void {
    // Write Zig code to temporary file
    const tmp_dir = try std.fs.createTmpDir(.{ .prefix = "zyth_" });
    defer tmp_dir.cleanup() catch {};

    const tmp_file_path = try std.fs.path.join(allocator, &[_][]const u8{ "/tmp", "zyth_XXXXXX", "main.zig" });
    defer allocator.free(tmp_file_path);

    // Create temp file
    var tmp_file = try tmp_dir.createFile("main.zig", .{});
    defer tmp_file.close();

    try tmp_file.writeAll(zig_code);

    // Get absolute path of temp file
    const cwd = try std.process.getCwd(allocator);
    defer allocator.free(cwd);

    // Shell out to zig build-exe
    const zig_path = try findZigBinary(allocator);
    defer allocator.free(zig_path);

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{
            zig_path,
            "build-exe",
            try std.fmt.allocPrint(allocator, "/tmp/zyth_*/main.zig", .{}), // TODO: Use actual tmp path
            "-O",
            "Debug",
            "--name",
            output_path,
        },
    });

    if (result.term.Exited != 0) {
        std.debug.print("Zig compilation failed:\n{s}\n", .{result.stderr});
        return error.ZigCompilationFailed;
    }
}

fn findZigBinary(allocator: std.mem.Allocator) ![]const u8 {
    // Try to find zig in PATH
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "which", "zig" },
    }) catch {
        // Default to "zig" and hope it's in PATH
        return try allocator.dupe(u8, "zig");
    };

    if (result.term.Exited == 0) {
        const path = std.mem.trim(u8, result.stdout, " \n\r\t");
        return try allocator.dupe(u8, path);
    }

    return try allocator.dupe(u8, "zig");
}
