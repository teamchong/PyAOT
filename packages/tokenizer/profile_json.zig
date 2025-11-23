/// Profile JSON parsing to find bottlenecks
const std = @import("std");
const runtime = @import("src/runtime.zig");
const json_module = @import("src/json.zig");
const allocator_helper = @import("src/allocator_helper.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = allocator_helper.getBenchmarkAllocator(gpa);

    const file = try std.fs.cwd().openFile("sample.json", .{});
    defer file.close();
    const json_data = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(json_data);

    const json_str = try runtime.PyString.create(allocator, json_data);
    defer runtime.decref(json_str, allocator);

    // Warm up
    {
        const parsed = try json_module.loads(json_str, allocator);
        runtime.decref(parsed, allocator);
    }

    // Profile parse iterations
    const iterations: usize = 1000;
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        const parsed = try json_module.loads(json_str, allocator);
        runtime.decref(parsed, allocator);
    }

    const elapsed = timer.read();
    const ms = elapsed / std.time.ns_per_ms;
    const per_iter = elapsed / iterations;

    std.debug.print("Total: {}ms\n", .{ms});
    std.debug.print("Per iteration: {}ns\n", .{per_iter});
    std.debug.print("Throughput: {d:.2} MB/s\n", .{
        @as(f64, @floatFromInt(json_data.len * iterations)) /
        (@as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0) / 1_000_000.0
    });
}
