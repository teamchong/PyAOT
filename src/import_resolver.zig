/// Import resolution for multi-file Python projects
const std = @import("std");
const builtin = @import("builtin");

/// Discover Python site-packages directories for Python 3.8-3.13
/// Returns owned slice of directory paths (caller must free)
pub fn discoverSitePackages(allocator: std.mem.Allocator) ![][]const u8 {
    var paths = std.ArrayList([]const u8){};
    errdefer {
        for (paths.items) |path| allocator.free(path);
        paths.deinit(allocator);
    }

    // Check for virtual environment first (VIRTUAL_ENV env var)
    if (std.posix.getenv("VIRTUAL_ENV")) |venv| {
        var venv_version: u8 = 8;
        while (venv_version <= 13) : (venv_version += 1) {
            const venv_path = std.fmt.allocPrint(
                allocator,
                "{s}/lib/python3.{d}/site-packages",
                .{ venv, venv_version },
            ) catch continue;
            paths.append(allocator, venv_path) catch allocator.free(venv_path);
        }
    }

    // Also check for .venv in current directory (common pattern)
    var local_venv_version: u8 = 8;
    while (local_venv_version <= 13) : (local_venv_version += 1) {
        const local_venv = std.fmt.allocPrint(
            allocator,
            ".venv/lib/python3.{d}/site-packages",
            .{local_venv_version},
        ) catch continue;
        paths.append(allocator, local_venv) catch allocator.free(local_venv);
    }

    switch (builtin.os.tag) {
        .linux, .freebsd, .openbsd, .netbsd => {
            // Linux/BSD paths
            var version: u8 = 8;
            while (version <= 13) : (version += 1) {
                // System site-packages
                const sys_path = try std.fmt.allocPrint(
                    allocator,
                    "/usr/lib/python3.{d}/site-packages",
                    .{version},
                );
                paths.append(allocator, sys_path) catch allocator.free(sys_path);

                const local_path = try std.fmt.allocPrint(
                    allocator,
                    "/usr/local/lib/python3.{d}/site-packages",
                    .{version},
                );
                paths.append(allocator, local_path) catch allocator.free(local_path);

                // User site-packages
                if (std.posix.getenv("HOME")) |home| {
                    const user_path = try std.fmt.allocPrint(
                        allocator,
                        "{s}/.local/lib/python3.{d}/site-packages",
                        .{ home, version },
                    );
                    paths.append(allocator, user_path) catch allocator.free(user_path);
                }
            }
        },
        .macos => {
            // macOS paths
            var version: u8 = 8;
            while (version <= 13) : (version += 1) {
                // Framework installation
                const framework_path = try std.fmt.allocPrint(
                    allocator,
                    "/Library/Frameworks/Python.framework/Versions/3.{d}/lib/python3.{d}/site-packages",
                    .{ version, version },
                );
                paths.append(allocator, framework_path) catch allocator.free(framework_path);

                // Homebrew/local
                const local_path = try std.fmt.allocPrint(
                    allocator,
                    "/usr/local/lib/python3.{d}/site-packages",
                    .{version},
                );
                paths.append(allocator, local_path) catch allocator.free(local_path);

                // User site-packages
                if (std.posix.getenv("HOME")) |home| {
                    const user_path = try std.fmt.allocPrint(
                        allocator,
                        "{s}/Library/Python/3.{d}/lib/python/site-packages",
                        .{ home, version },
                    );
                    paths.append(allocator, user_path) catch allocator.free(user_path);
                }
            }
        },
        .windows => {
            // Windows paths
            var version: u8 = 8;
            while (version <= 13) : (version += 1) {
                // Standard installation
                const sys_path = try std.fmt.allocPrint(
                    allocator,
                    "C:\\Python3{d}\\Lib\\site-packages",
                    .{version},
                );
                paths.append(allocator, sys_path) catch allocator.free(sys_path);

                // AppData installation
                if (std.posix.getenv("APPDATA")) |appdata| {
                    const user_path = try std.fmt.allocPrint(
                        allocator,
                        "{s}\\Python\\Python3{d}\\site-packages",
                        .{ appdata, version },
                    );
                    paths.append(allocator, user_path) catch allocator.free(user_path);
                }
            }
        },
        else => {
            // Unsupported platform - return empty list
        },
    }

    return paths.toOwnedSlice(allocator);
}

/// Find a module in site-packages directories
/// Returns owned path to module or null if not found
pub fn findInSitePackages(
    module_name: []const u8,
    allocator: std.mem.Allocator,
) !?[]const u8 {
    const site_packages = try discoverSitePackages(allocator);
    defer {
        for (site_packages) |path| allocator.free(path);
        allocator.free(site_packages);
    }

    for (site_packages) |site_dir| {
        // Try direct module file: site-packages/module.py
        const module_file = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}.py",
            .{ site_dir, module_name },
        );

        std.fs.cwd().access(module_file, .{}) catch {
            allocator.free(module_file);

            // Try package __init__.py: site-packages/module/__init__.py
            const package_init = try std.fmt.allocPrint(
                allocator,
                "{s}/{s}/__init__.py",
                .{ site_dir, module_name },
            );

            std.fs.cwd().access(package_init, .{}) catch {
                allocator.free(package_init);
                continue;
            };

            return package_init;
        };

        return module_file;
    }

    return null;
}

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
    // 4. Site-packages directories

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

    // Try site-packages as fallback
    if (try findInSitePackages(module_name, allocator)) |site_path| {
        return site_path;
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

/// Check if a module is a C extension (.so, .dylib, .pyd)
/// Searches site-packages and virtual env paths
pub fn isCExtension(
    module_name: []const u8,
    allocator: std.mem.Allocator,
) bool {
    // C extension file suffixes by platform
    const extensions = switch (builtin.os.tag) {
        .macos => &[_][]const u8{ ".so", ".dylib" },
        .windows => &[_][]const u8{ ".pyd", ".dll" },
        else => &[_][]const u8{".so"},
    };

    // Get site-packages directories
    const site_packages = discoverSitePackages(allocator) catch return false;
    defer {
        for (site_packages) |path| allocator.free(path);
        allocator.free(site_packages);
    }

    // Check each site-packages directory for C extension files
    for (site_packages) |site_dir| {
        for (extensions) |ext| {
            const full_path = std.fmt.allocPrint(
                allocator,
                "{s}/{s}{s}",
                .{ site_dir, module_name, ext },
            ) catch continue;
            defer allocator.free(full_path);

            std.fs.cwd().access(full_path, .{}) catch continue;

            // Found a C extension!
            return true;
        }
    }

    return false;
}
