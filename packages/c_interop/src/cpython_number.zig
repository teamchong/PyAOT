/// CPython Number Protocol Implementation
///
/// This implements the number protocol for arithmetic operations.
/// Critical for NumPy array arithmetic (+, -, *, /, etc.)

const std = @import("std");
const cpython = @import("cpython_object.zig");

// External dependencies
extern fn Py_INCREF(*cpython.PyObject) callconv(.c) void;
extern fn Py_DECREF(*cpython.PyObject) callconv(.c) void;
extern fn PyErr_SetString(*cpython.PyObject, [*:0]const u8) callconv(.c) void;
extern fn PyErr_Occurred() callconv(.c) ?*cpython.PyObject;

/// Check if object is a number
export fn PyNumber_Check(obj: *cpython.PyObject) callconv(.c) c_int {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |_| {
        return 1;
    }
    
    return 0;
}

/// Add two numbers
export fn PyNumber_Add(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_add) |add_func| {
            return add_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for +");
    return null;
}

/// Subtract two numbers
export fn PyNumber_Subtract(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_subtract) |sub_func| {
            return sub_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for -");
    return null;
}

/// Multiply two numbers
export fn PyNumber_Multiply(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_multiply) |mul_func| {
            return mul_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for *");
    return null;
}

/// Matrix multiply (NumPy @)
export fn PyNumber_MatrixMultiply(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_matrix_multiply) |matmul_func| {
            return matmul_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for @");
    return null;
}

/// Floor division
export fn PyNumber_FloorDivide(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_floor_divide) |div_func| {
            return div_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for //");
    return null;
}

/// True division
export fn PyNumber_TrueDivide(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_true_divide) |div_func| {
            return div_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for /");
    return null;
}

/// Remainder
export fn PyNumber_Remainder(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_remainder) |mod_func| {
            return mod_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for %");
    return null;
}

/// Divmod
export fn PyNumber_Divmod(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_divmod) |divmod_func| {
            return divmod_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for divmod()");
    return null;
}

/// Power
export fn PyNumber_Power(a: *cpython.PyObject, b: *cpython.PyObject, c: ?*cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_power) |pow_func| {
            return pow_func(a, b, c orelse @ptrFromInt(0));
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for **");
    return null;
}

/// Negative
export fn PyNumber_Negative(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_negative) |neg_func| {
            return neg_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "bad operand type for unary -");
    return null;
}

/// Positive
export fn PyNumber_Positive(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_positive) |pos_func| {
            return pos_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "bad operand type for unary +");
    return null;
}

/// Absolute value
export fn PyNumber_Absolute(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_absolute) |abs_func| {
            return abs_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "bad operand type for abs()");
    return null;
}

/// Invert
export fn PyNumber_Invert(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_invert) |invert_func| {
            return invert_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "bad operand type for unary ~");
    return null;
}

/// Left shift
export fn PyNumber_Lshift(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_lshift) |lshift_func| {
            return lshift_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for <<");
    return null;
}

/// Right shift
export fn PyNumber_Rshift(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_rshift) |rshift_func| {
            return rshift_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for >>");
    return null;
}

/// Bitwise AND
export fn PyNumber_And(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_and) |and_func| {
            return and_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for &");
    return null;
}

/// Bitwise XOR
export fn PyNumber_Xor(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_xor) |xor_func| {
            return xor_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for ^");
    return null;
}

/// Bitwise OR
export fn PyNumber_Or(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_or) |or_func| {
            return or_func(a, b);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "unsupported operand type(s) for |");
    return null;
}

/// In-place add
export fn PyNumber_InPlaceAdd(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_inplace_add) |iadd_func| {
            return iadd_func(a, b);
        }
    }
    
    // Fallback to regular add
    return PyNumber_Add(a, b);
}

/// In-place subtract
export fn PyNumber_InPlaceSubtract(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_inplace_subtract) |isub_func| {
            return isub_func(a, b);
        }
    }
    
    // Fallback to regular subtract
    return PyNumber_Subtract(a, b);
}

/// In-place multiply
export fn PyNumber_InPlaceMultiply(a: *cpython.PyObject, b: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(a);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_inplace_multiply) |imul_func| {
            return imul_func(a, b);
        }
    }
    
    // Fallback to regular multiply
    return PyNumber_Multiply(a, b);
}

/// Convert to long
export fn PyNumber_Long(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_int) |int_func| {
            return int_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "int() argument must be a number");
    return null;
}

/// Convert to float
export fn PyNumber_Float(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_float) |float_func| {
            return float_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "float() argument must be a number");
    return null;
}

/// Get index value
export fn PyNumber_Index(obj: *cpython.PyObject) callconv(.c) ?*cpython.PyObject {
    const type_obj = cpython.Py_TYPE(obj);
    
    if (type_obj.tp_as_number) |number_procs| {
        if (number_procs.nb_index) |index_func| {
            return index_func(obj);
        }
    }
    
    PyErr_SetString(@ptrFromInt(0), "object cannot be interpreted as an integer");
    return null;
}

/// Convert to C ssize_t
export fn PyNumber_AsSsize_t(obj: *cpython.PyObject, exc: ?*cpython.PyObject) callconv(.c) isize {
    _ = exc;
    
    // Try to convert to long first
    const long_obj = PyNumber_Long(obj);
    if (long_obj == null) return -1;
    defer if (long_obj) |l| Py_DECREF(l);
    
    // Extract value (simplified)
    // TODO: Use PyLong_AsSsize_t when available
    return 0;
}

// Tests
test "PyNumber function exports" {
    // Just verify functions exist and can be referenced
    _ = PyNumber_Check;
    _ = PyNumber_Add;
    _ = PyNumber_Multiply;
    _ = PyNumber_MatrixMultiply;
}
