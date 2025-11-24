/// Python asyncio module implementation
/// Built on top of our EventLoop (inspired by Bun)
const std = @import("std");
const runtime = @import("runtime.zig");
const EventLoop = @import("../../async_runtime/src/EventLoop.zig");

/// Global event loop instance
var global_loop: ?*EventLoop = null;
var global_allocator: std.mem.Allocator = undefined;

/// Initialize asyncio module
pub fn init(allocator: std.mem.Allocator) !void {
    global_allocator = allocator;
}

/// Get or create event loop
fn getEventLoop() !*EventLoop {
    if (global_loop == null) {
        const loop = try global_allocator.create(EventLoop);
        loop.* = try EventLoop.init(global_allocator);
        global_loop = loop;
    }
    return global_loop.?;
}

/// asyncio.run(coro) - Run coroutine to completion
pub fn run(allocator: std.mem.Allocator, coro: *runtime.PyObject) !*runtime.PyObject {
    _ = allocator;
    const loop = try getEventLoop();

    // TODO: Execute coroutine
    _ = coro;

    // Run event loop
    try loop.run();

    // Return None for now
    return try runtime.PyObject.none(allocator);
}

/// asyncio.sleep(seconds) - Async sleep
pub fn sleep(allocator: std.mem.Allocator, seconds: f64) !*runtime.PyObject {
    const loop = try getEventLoop();

    const delay_ns: i64 = @intFromFloat(seconds * @as(f64, std.time.ns_per_s));

    var completed = false;
    const callback = struct {
        fn cb(data: *anyopaque) void {
            const ptr = @as(*bool, @ptrCast(@alignCast(data)));
            ptr.* = true;
        }
    }.cb;

    try loop.scheduleTimer(delay_ns, callback, &completed);

    // Return None
    return try runtime.PyObject.none(allocator);
}

/// asyncio.create_task(coro) - Create task from coroutine
pub fn createTask(allocator: std.mem.Allocator, coro: *runtime.PyObject) !*runtime.PyObject {
    const loop = try getEventLoop();

    const callback = struct {
        fn cb(data: *anyopaque) void {
            const obj = @as(*runtime.PyObject, @ptrCast(@alignCast(data)));
            _ = obj;
            // TODO: Execute coroutine
        }
    }.cb;

    try loop.queueTask(callback, coro);

    // Return task object (for now, just return the coro)
    return coro;
}

/// asyncio.gather(*awaitables) - Run multiple coroutines concurrently
pub fn gather(allocator: std.mem.Allocator, awaitables: *runtime.PyList) !*runtime.PyObject {
    _ = allocator;
    const loop = try getEventLoop();

    // Queue all awaitables as tasks
    for (awaitables.items.items) |item| {
        const callback = struct {
            fn cb(data: *anyopaque) void {
                const obj = @as(*runtime.PyObject, @ptrCast(@alignCast(data)));
                _ = obj;
                // TODO: Execute awaitable
            }
        }.cb;

        try loop.queueTask(callback, item);
    }

    // Return list of results (TODO: implement properly)
    return @ptrCast(awaitables);
}

/// Cleanup asyncio module
pub fn deinit() void {
    if (global_loop) |loop| {
        loop.deinit();
        global_allocator.destroy(loop);
        global_loop = null;
    }
}

// Tests
test "asyncio.sleep" {
    try init(std.testing.allocator);
    defer deinit();

    const result = try sleep(std.testing.allocator, 0.01);
    _ = result;
}
