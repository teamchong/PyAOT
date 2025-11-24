/// CPython Buffer Protocol Implementation
///
/// This implements the buffer protocol needed for NumPy array interfacing.
/// The buffer protocol allows efficient access to array data without copying.

const std = @import("std");
const cpython = @import("cpython_object.zig");

const allocator = std.heap.c_allocator;

// External dependencies
extern fn Py_INCREF(*cpython.PyObject) callconv(.c) void;
extern fn Py_DECREF(*cpython.PyObject) callconv(.c) void;
extern fn PyErr_SetString(*cpython.PyObject, [*:0]const u8) callconv(.c) void;

// Buffer request flags
pub const PyBUF_SIMPLE: c_int = 0;
pub const PyBUF_WRITABLE: c_int = 0x0001;
pub const PyBUF_FORMAT: c_int = 0x0004;
pub const PyBUF_ND: c_int = 0x0008;
pub const PyBUF_STRIDES: c_int = 0x0010 | PyBUF_ND;
pub const PyBUF_C_CONTIGUOUS: c_int = 0x0020 | PyBUF_STRIDES;
pub const PyBUF_F_CONTIGUOUS: c_int = 0x0040 | PyBUF_STRIDES;
pub const PyBUF_ANY_CONTIGUOUS: c_int = 0x0080 | PyBUF_STRIDES;
pub const PyBUF_INDIRECT: c_int = 0x0100 | PyBUF_STRIDES;

/// Buffer structure (must match CPython layout)
pub const Py_buffer = extern struct {
    buf: ?*anyopaque,
    obj: ?*cpython.PyObject,
    len: isize,
    itemsize: isize,
    readonly: c_int,
    ndim: c_int,
    format: ?[*:0]u8,
    shape: ?[*]isize,
    strides: ?[*]isize,
    suboffsets: ?[*]isize,
    internal: ?*anyopaque,
};

/// Get buffer from object
export fn PyObject_GetBuffer(obj: *cpython.PyObject, view: *Py_buffer, flags: c_int) callconv(.c) c_int {
    const type_obj = cpython.Py_TYPE(obj);
    
    // Check if type supports buffer protocol
    if (type_obj.tp_as_buffer) |buffer_procs| {
        if (buffer_procs.bf_getbuffer) |getbuffer| {
            return getbuffer(obj, view, flags);
        }
    }
    
    // Type doesn't support buffer protocol
    PyErr_SetString(@ptrFromInt(0), "object does not support buffer protocol");
    return -1;
}

/// Release buffer
export fn PyBuffer_Release(view: *Py_buffer) callconv(.c) void {
    if (view.obj) |obj| {
        const type_obj = cpython.Py_TYPE(obj);
        
        if (type_obj.tp_as_buffer) |buffer_procs| {
            if (buffer_procs.bf_releasebuffer) |releasebuffer| {
                releasebuffer(obj, view);
            }
        }
        
        Py_DECREF(obj);
        view.obj = null;
    }
}

/// Get buffer size
export fn PyBuffer_SizeFromFormat(format: [*:0]const u8) callconv(.c) isize {
    const fmt = std.mem.span(format);
    
    // Simple format codes
    if (fmt.len == 1) {
        return switch (fmt[0]) {
            'c', 'b', 'B', '?' => 1,  // char, signed/unsigned byte, bool
            'h', 'H' => 2,             // short
            'i', 'I', 'l', 'L' => 4,   // int, long
            'q', 'Q' => 8,             // long long
            'f' => 4,                  // float
            'd' => 8,                  // double
            else => -1,
        };
    }
    
    return -1;
}

/// Check if buffer is contiguous
export fn PyBuffer_IsContiguous(view: *const Py_buffer, fort: u8) callconv(.c) c_int {
    _ = fort;
    
    // Simple check: if strides is null, it's C-contiguous
    if (view.strides == null) {
        return 1;
    }
    
    // TODO: Implement proper contiguity check
    return 0;
}

/// Fill contiguous buffer info
export fn PyBuffer_FillContiguousStrides(ndim: c_int, shape: [*]isize, strides: [*]isize, itemsize: isize, fort: u8) callconv(.c) void {
    if (fort == 'C' or fort == 'c') {
        // C-contiguous (row-major)
        var stride = itemsize;
        var i: isize = ndim - 1;
        while (i >= 0) : (i -= 1) {
            const idx: usize = @intCast(i);
            strides[idx] = stride;
            stride *= shape[idx];
        }
    } else {
        // Fortran-contiguous (column-major)
        var stride = itemsize;
        var i: usize = 0;
        while (i < ndim) : (i += 1) {
            strides[i] = stride;
            stride *= shape[i];
        }
    }
}

/// Fill buffer info from object
export fn PyBuffer_FillInfo(view: *Py_buffer, obj: ?*cpython.PyObject, buf: ?*anyopaque, len: isize, readonly: c_int, flags: c_int) callconv(.c) c_int {
    _ = flags;
    
    view.buf = buf;
    view.obj = obj;
    view.len = len;
    view.itemsize = 1;
    view.readonly = readonly;
    view.ndim = 1;
    view.format = null;
    view.shape = null;
    view.strides = null;
    view.suboffsets = null;
    view.internal = null;
    
    if (obj) |o| {
        Py_INCREF(o);
    }
    
    return 0;
}

/// Get pointer to buffer data
export fn PyBuffer_GetPointer(view: *Py_buffer, indices: [*]isize) callconv(.c) ?*anyopaque {
    const buf_ptr: [*]u8 = @ptrCast(view.buf orelse return null);
    var offset: isize = 0;
    
    if (view.strides) |strides| {
        var i: usize = 0;
        while (i < view.ndim) : (i += 1) {
            offset += indices[i] * strides[i];
        }
    } else {
        // C-contiguous
        var stride = view.itemsize;
        var i: isize = @as(isize, @intCast(view.ndim)) - 1;
        while (i >= 0) : (i -= 1) {
            const idx: usize = @intCast(i);
            offset += indices[idx] * stride;
            if (i > 0 and view.shape != null) {
                stride *= view.shape.?[idx];
            }
        }
    }
    
    const offset_usize: usize = @intCast(offset);
    return @ptrCast(&buf_ptr[offset_usize]);
}

/// Convert from/to buffer
export fn PyObject_CopyData(dest: *cpython.PyObject, src: *cpython.PyObject) callconv(.c) c_int {
    var dest_view: Py_buffer = undefined;
    var src_view: Py_buffer = undefined;
    
    if (PyObject_GetBuffer(dest, &dest_view, PyBUF_WRITABLE) != 0) {
        return -1;
    }
    defer PyBuffer_Release(&dest_view);
    
    if (PyObject_GetBuffer(src, &src_view, PyBUF_SIMPLE) != 0) {
        return -1;
    }
    defer PyBuffer_Release(&src_view);
    
    if (dest_view.len != src_view.len) {
        PyErr_SetString(@ptrFromInt(0), "buffer sizes do not match");
        return -1;
    }
    
    // Copy data
    const dest_ptr: [*]u8 = @ptrCast(dest_view.buf orelse return -1);
    const src_ptr: [*]const u8 = @ptrCast(src_view.buf orelse return -1);
    const len: usize = @intCast(dest_view.len);
    
    @memcpy(dest_ptr[0..len], src_ptr[0..len]);
    
    return 0;
}

/// Check if object supports buffer protocol
export fn PyObject_CheckBuffer(obj: *cpython.PyObject) callconv(.c) c_int {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_buffer) |buffer_procs| {
        if (buffer_procs.bf_getbuffer != null) {
            return 1;
        }
    }
    
    return 0;
}

// Tests
test "Py_buffer size" {
    // Verify struct matches CPython layout
    try std.testing.expectEqual(@sizeOf(Py_buffer), 80); // On 64-bit
}

test "PyBuffer_SizeFromFormat" {
    try std.testing.expectEqual(PyBuffer_SizeFromFormat("b"), 1);
    try std.testing.expectEqual(PyBuffer_SizeFromFormat("h"), 2);
    try std.testing.expectEqual(PyBuffer_SizeFromFormat("i"), 4);
    try std.testing.expectEqual(PyBuffer_SizeFromFormat("q"), 8);
    try std.testing.expectEqual(PyBuffer_SizeFromFormat("f"), 4);
    try std.testing.expectEqual(PyBuffer_SizeFromFormat("d"), 8);
}

test "PyBuffer_FillContiguousStrides C-order" {
    var shape = [_]isize{ 3, 4, 5 };
    var strides = [_]isize{ 0, 0, 0 };
    
    PyBuffer_FillContiguousStrides(3, &shape, &strides, 4); // 4-byte items
    
    try std.testing.expectEqual(strides[0], 80);  // 4*5*4
    try std.testing.expectEqual(strides[1], 20);  // 5*4
    try std.testing.expectEqual(strides[2], 4);   // 4
}
