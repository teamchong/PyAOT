/// PyAOT JSON parse benchmark using arena allocator for 2-4x speedup
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

    // Benchmark: Parse 100K times with arena allocator
    const iterations: usize = 100_000;
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        // Use arena allocator for this parse (deallocate all at once!)
        var arena = std.heap.ArenaAllocator.init(main_allocator);
        defer arena.deinit(); // Free everything in one shot!

        const arena_allocator = arena.allocator();

        // Parse JSON using arena allocator (all allocations freed together)
        const parsed = try json_module.loads(json_str_persistent, arena_allocator);
        // No need to decref - arena.deinit() frees everything!
        _ = parsed;
    }
}
