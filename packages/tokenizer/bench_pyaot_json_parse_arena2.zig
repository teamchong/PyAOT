/// PyAOT JSON parse benchmark using reusable arena allocator
const std = @import("std");
const runtime = @import("src/runtime.zig");
const json_module = @import("src/json.zig");
const allocator_helper = @import("src/allocator_helper.zig");

pub fn main() !void {
    // Main allocator for file reading
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const main_allocator = allocator_helper.getBenchmarkAllocator(gpa);

    // Read JSON file once
    const file = try std.fs.cwd().openFile("sample.json", .{});
    defer file.close();
    const json_data = try file.readToEndAlloc(main_allocator, 1024 * 1024);
    defer main_allocator.free(json_data);

    const json_str_persistent = try runtime.PyString.create(main_allocator, json_data);
    defer runtime.decref(json_str_persistent, main_allocator);

    // Create arena once, reuse for all iterations (faster than creating/destroying!)
    var arena = std.heap.ArenaAllocator.init(main_allocator);
    defer arena.deinit();

    // Benchmark: Parse 100K times reusing the same arena
    const iterations: usize = 100_000;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const arena_allocator = arena.allocator();

        // Parse JSON using arena allocator
        const parsed = try json_module.loads(json_str_persistent, arena_allocator);
        _ = parsed;

        // Reset arena for next iteration (frees all memory, keeps capacity)
        _ = arena.reset(.retain_capacity);
    }
}
