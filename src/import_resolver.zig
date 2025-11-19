/// Import resolution for multi-file Python projects
const std = @import("std");

/// Resolve a Python module import to a .py file path
/// Returns null if module is not a local .py file
pub fn resolveImport(
    module_name: []const u8,
    source_file_dir: ?[]const u8,
    allocator: std.mem.Allocator,
) !?[]const u8 {
    // Try different search paths in order of priority:
    // 1. Same directory as source file (if provided)
    // 2. Current working directory
    // 3. examples/ directory (for backward compatibility)

    var search_paths = std.ArrayList([]const u8){};
    defer search_paths.deinit(allocator);

    // Add source file directory as first priority
    if (source_file_dir) |dir| {
        try search_paths.append(allocator, dir);
    }

    // Add current directory
    try search_paths.append(allocator, ".");

    // Add examples directory
    try search_paths.append(allocator, "examples");

    // Try each search path
    for (search_paths.items) |search_dir| {
        const py_path = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}.py",
            .{ search_dir, module_name },
        );

        // Check if file exists
        std.fs.cwd().access(py_path, .{}) catch {
            allocator.free(py_path);
            continue;
        };

        // File found!
        return py_path;
    }

    // Not found in any search path
    return null;
}

/// Check if a module name refers to a local Python file
pub fn isLocalModule(
    module_name: []const u8,
    source_file_dir: ?[]const u8,
    allocator: std.mem.Allocator,
) !bool {
    const resolved = try resolveImport(module_name, source_file_dir, allocator);
    if (resolved) |path| {
        allocator.free(path);
        return true;
    }
    return false;
}

/// Extract the directory from a file path
/// Returns "." if path has no directory component
pub fn getFileDirectory(file_path: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    // Find last slash
    var i = file_path.len;
    while (i > 0) {
        i -= 1;
        if (file_path[i] == '/' or file_path[i] == '\\') {
            // Return everything before the slash
            return try allocator.dupe(u8, file_path[0..i]);
        }
    }

    // No slash found - file is in current directory
    return try allocator.dupe(u8, ".");
}
