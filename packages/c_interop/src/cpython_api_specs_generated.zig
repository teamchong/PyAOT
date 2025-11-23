/// Auto-generated CPython API Specs
/// Generated from CPython header files
/// DO NOT EDIT MANUALLY - regenerate with parse_cpython_headers.py

const std = @import("std");


/// ============================================================================
///  (54 functions)
/// ============================================================================

pub const _SPECS = [_]CPythonAPISpec{
    .{
        .name = "Py_Is",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "Py_Is from object.h",
    },
    .{
        .name = "PyType_FromSpec",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_FromSpec from object.h",
    },
    .{
        .name = "PyType_FromSpecWithBases",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_FromSpecWithBases from object.h",
    },
    .{
        .name = "PyType_GetSlot",
        .args = &[_]type{ *anyopaque, c_int },
        .returns = *void,
        .doc = "PyType_GetSlot from object.h",
    },
    .{
        .name = "PyType_FromModuleAndSpec",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_FromModuleAndSpec from object.h",
    },
    .{
        .name = "PyType_GetModule",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_GetModule from object.h",
    },
    .{
        .name = "PyType_GetModuleState",
        .args = &[_]type{ *anyopaque },
        .returns = *void,
        .doc = "PyType_GetModuleState from object.h",
    },
    .{
        .name = "PyType_GetName",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_GetName from object.h",
    },
    .{
        .name = "PyType_GetQualName",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_GetQualName from object.h",
    },
    .{
        .name = "PyType_FromMetaclass",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyType_FromMetaclass from object.h",
    },
    .{
        .name = "PyObject_GetTypeData",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *void,
        .doc = "PyObject_GetTypeData from object.h",
    },
    .{
        .name = "PyType_GetTypeDataSize",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyType_GetTypeDataSize from object.h",
    },
    .{
        .name = "PyType_IsSubtype",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyType_IsSubtype from object.h",
    },
    .{
        .name = "PyType_GetFlags",
        .args = &[_]type{ *anyopaque },
        .returns = c_ulong,
        .doc = "PyType_GetFlags from object.h",
    },
    .{
        .name = "PyType_Ready",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyType_Ready from object.h",
    },
    .{
        .name = "PyType_GenericAlloc",
        .args = &[_]type{ *anyopaque, isize },
        .returns = *anyopaque,
        .doc = "PyType_GenericAlloc from object.h",
    },
    .{
        .name = "PyType_ClearCache",
        .args = &[_]type{  },
        .returns = anyopaque,
        .doc = "PyType_ClearCache from object.h",
    },
    .{
        .name = "PyType_Modified",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyType_Modified from object.h",
    },
    .{
        .name = "PyObject_Repr",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_Repr from object.h",
    },
    .{
        .name = "PyObject_Str",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_Str from object.h",
    },
    .{
        .name = "PyObject_ASCII",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_ASCII from object.h",
    },
    .{
        .name = "PyObject_Bytes",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_Bytes from object.h",
    },
    .{
        .name = "PyObject_RichCompare",
        .args = &[_]type{ *anyopaque, *anyopaque, c_int },
        .returns = *anyopaque,
        .doc = "PyObject_RichCompare from object.h",
    },
    .{
        .name = "PyObject_RichCompareBool",
        .args = &[_]type{ *anyopaque, *anyopaque, c_int },
        .returns = c_int,
        .doc = "PyObject_RichCompareBool from object.h",
    },
    .{
        .name = "PyObject_GetAttrString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = *anyopaque,
        .doc = "PyObject_GetAttrString from object.h",
    },
    .{
        .name = "PyObject_SetAttrString",
        .args = &[_]type{ *anyopaque, *const u8, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_SetAttrString from object.h",
    },
    .{
        .name = "PyObject_HasAttrString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = c_int,
        .doc = "PyObject_HasAttrString from object.h",
    },
    .{
        .name = "PyObject_GetAttr",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_GetAttr from object.h",
    },
    .{
        .name = "PyObject_SetAttr",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_SetAttr from object.h",
    },
    .{
        .name = "PyObject_HasAttr",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_HasAttr from object.h",
    },
    .{
        .name = "PyObject_SelfIter",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_SelfIter from object.h",
    },
    .{
        .name = "PyObject_GenericGetAttr",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_GenericGetAttr from object.h",
    },
    .{
        .name = "PyObject_GenericSetAttr",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_GenericSetAttr from object.h",
    },
    .{
        .name = "PyObject_GenericSetDict",
        .args = &[_]type{ *anyopaque, *anyopaque, *void },
        .returns = c_int,
        .doc = "PyObject_GenericSetDict from object.h",
    },
    .{
        .name = "PyObject_Hash",
        .args = &[_]type{ *anyopaque },
        .returns = anyopaque,
        .doc = "PyObject_Hash from object.h",
    },
    .{
        .name = "PyObject_HashNotImplemented",
        .args = &[_]type{ *anyopaque },
        .returns = anyopaque,
        .doc = "PyObject_HashNotImplemented from object.h",
    },
    .{
        .name = "PyObject_IsTrue",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyObject_IsTrue from object.h",
    },
    .{
        .name = "PyObject_Not",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyObject_Not from object.h",
    },
    .{
        .name = "PyCallable_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyCallable_Check from object.h",
    },
    .{
        .name = "PyObject_ClearWeakRefs",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyObject_ClearWeakRefs from object.h",
    },
    .{
        .name = "PyObject_Dir",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_Dir from object.h",
    },
    .{
        .name = "_PyObject_GetState",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "_PyObject_GetState from object.h",
    },
    .{
        .name = "Py_ReprEnter",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "Py_ReprEnter from object.h",
    },
    .{
        .name = "Py_ReprLeave",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "Py_ReprLeave from object.h",
    },
    .{
        .name = "_Py_INCREF_IncRefTotal",
        .args = &[_]type{  },
        .returns = void,
        .doc = "_Py_INCREF_IncRefTotal from object.h",
    },
    .{
        .name = "_Py_DECREF_DecRefTotal",
        .args = &[_]type{  },
        .returns = void,
        .doc = "_Py_DECREF_DecRefTotal from object.h",
    },
    .{
        .name = "_Py_Dealloc",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "_Py_Dealloc from object.h",
    },
    .{
        .name = "Py_IncRef",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "Py_IncRef from object.h",
    },
    .{
        .name = "Py_DecRef",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "Py_DecRef from object.h",
    },
    .{
        .name = "_Py_IncRef",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "_Py_IncRef from object.h",
    },
    .{
        .name = "_Py_DecRef",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "_Py_DecRef from object.h",
    },
    .{
        .name = "Py_NewRef",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "Py_NewRef from object.h",
    },
    .{
        .name = "Py_XNewRef",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "Py_XNewRef from object.h",
    },
    .{
        .name = "Py_IsNone",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "Py_IsNone from object.h",
    },
};

/// ============================================================================
/// ABSTRACT (81 functions)
/// ============================================================================

pub const ABSTRACT_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyCallable_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyCallable_Check from abstract.h",
    },
    .{
        .name = "PyObject_CallNoArgs",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_CallNoArgs from abstract.h",
    },
    .{
        .name = "PyVectorcall_NARGS",
        .args = &[_]type{ usize },
        .returns = isize,
        .doc = "PyVectorcall_NARGS from abstract.h",
    },
    .{
        .name = "PyVectorcall_Call",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyVectorcall_Call from abstract.h",
    },
    .{
        .name = "PyObject_Type",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_Type from abstract.h",
    },
    .{
        .name = "PyObject_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyObject_Size from abstract.h",
    },
    .{
        .name = "PyObject_Length",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyObject_Length from abstract.h",
    },
    .{
        .name = "PyObject_GetItem",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_GetItem from abstract.h",
    },
    .{
        .name = "PyObject_SetItem",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_SetItem from abstract.h",
    },
    .{
        .name = "PyObject_DelItemString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = c_int,
        .doc = "PyObject_DelItemString from abstract.h",
    },
    .{
        .name = "PyObject_DelItem",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_DelItem from abstract.h",
    },
    .{
        .name = "PyObject_CheckReadBuffer",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyObject_CheckReadBuffer from abstract.h",
    },
    .{
        .name = "PyObject_GetIter",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_GetIter from abstract.h",
    },
    .{
        .name = "PyObject_GetAIter",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyObject_GetAIter from abstract.h",
    },
    .{
        .name = "PyIter_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyIter_Check from abstract.h",
    },
    .{
        .name = "PyAIter_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyAIter_Check from abstract.h",
    },
    .{
        .name = "PyIter_Next",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyIter_Next from abstract.h",
    },
    .{
        .name = "PyIter_Send",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = anyopaque,
        .doc = "PyIter_Send from abstract.h",
    },
    .{
        .name = "PyNumber_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyNumber_Check from abstract.h",
    },
    .{
        .name = "PyNumber_Add",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Add from abstract.h",
    },
    .{
        .name = "PyNumber_Subtract",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Subtract from abstract.h",
    },
    .{
        .name = "PyNumber_Multiply",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Multiply from abstract.h",
    },
    .{
        .name = "PyNumber_MatrixMultiply",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_MatrixMultiply from abstract.h",
    },
    .{
        .name = "PyNumber_FloorDivide",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_FloorDivide from abstract.h",
    },
    .{
        .name = "PyNumber_TrueDivide",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_TrueDivide from abstract.h",
    },
    .{
        .name = "PyNumber_Remainder",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Remainder from abstract.h",
    },
    .{
        .name = "PyNumber_Divmod",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Divmod from abstract.h",
    },
    .{
        .name = "PyNumber_Negative",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Negative from abstract.h",
    },
    .{
        .name = "PyNumber_Positive",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Positive from abstract.h",
    },
    .{
        .name = "PyNumber_Absolute",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Absolute from abstract.h",
    },
    .{
        .name = "PyNumber_Invert",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Invert from abstract.h",
    },
    .{
        .name = "PyNumber_Lshift",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Lshift from abstract.h",
    },
    .{
        .name = "PyNumber_Rshift",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Rshift from abstract.h",
    },
    .{
        .name = "PyNumber_And",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_And from abstract.h",
    },
    .{
        .name = "PyNumber_Xor",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Xor from abstract.h",
    },
    .{
        .name = "PyNumber_Or",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Or from abstract.h",
    },
    .{
        .name = "PyIndex_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyIndex_Check from abstract.h",
    },
    .{
        .name = "PyNumber_Index",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Index from abstract.h",
    },
    .{
        .name = "PyNumber_AsSsize_t",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = isize,
        .doc = "PyNumber_AsSsize_t from abstract.h",
    },
    .{
        .name = "PyNumber_Long",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Long from abstract.h",
    },
    .{
        .name = "PyNumber_Float",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_Float from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceAdd",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceAdd from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceSubtract",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceSubtract from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceMultiply",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceMultiply from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceMatrixMultiply",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceMatrixMultiply from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceRemainder",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceRemainder from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceLshift",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceLshift from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceRshift",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceRshift from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceAnd",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceAnd from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceXor",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceXor from abstract.h",
    },
    .{
        .name = "PyNumber_InPlaceOr",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyNumber_InPlaceOr from abstract.h",
    },
    .{
        .name = "PyNumber_ToBase",
        .args = &[_]type{ *anyopaque, c_int },
        .returns = *anyopaque,
        .doc = "PyNumber_ToBase from abstract.h",
    },
    .{
        .name = "PySequence_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PySequence_Check from abstract.h",
    },
    .{
        .name = "PySequence_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PySequence_Size from abstract.h",
    },
    .{
        .name = "PySequence_Length",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PySequence_Length from abstract.h",
    },
    .{
        .name = "PySequence_Concat",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PySequence_Concat from abstract.h",
    },
    .{
        .name = "PySequence_Repeat",
        .args = &[_]type{ *anyopaque, isize },
        .returns = *anyopaque,
        .doc = "PySequence_Repeat from abstract.h",
    },
    .{
        .name = "PySequence_GetItem",
        .args = &[_]type{ *anyopaque, isize },
        .returns = *anyopaque,
        .doc = "PySequence_GetItem from abstract.h",
    },
    .{
        .name = "PySequence_GetSlice",
        .args = &[_]type{ *anyopaque, isize, isize },
        .returns = *anyopaque,
        .doc = "PySequence_GetSlice from abstract.h",
    },
    .{
        .name = "PySequence_SetItem",
        .args = &[_]type{ *anyopaque, isize, *anyopaque },
        .returns = c_int,
        .doc = "PySequence_SetItem from abstract.h",
    },
    .{
        .name = "PySequence_DelItem",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PySequence_DelItem from abstract.h",
    },
    .{
        .name = "PySequence_DelSlice",
        .args = &[_]type{ *anyopaque, isize, isize },
        .returns = c_int,
        .doc = "PySequence_DelSlice from abstract.h",
    },
    .{
        .name = "PySequence_Tuple",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PySequence_Tuple from abstract.h",
    },
    .{
        .name = "PySequence_List",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PySequence_List from abstract.h",
    },
    .{
        .name = "PySequence_Fast",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = *anyopaque,
        .doc = "PySequence_Fast from abstract.h",
    },
    .{
        .name = "PySequence_Count",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = isize,
        .doc = "PySequence_Count from abstract.h",
    },
    .{
        .name = "PySequence_Contains",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PySequence_Contains from abstract.h",
    },
    .{
        .name = "PySequence_In",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PySequence_In from abstract.h",
    },
    .{
        .name = "PySequence_Index",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = isize,
        .doc = "PySequence_Index from abstract.h",
    },
    .{
        .name = "PySequence_InPlaceConcat",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PySequence_InPlaceConcat from abstract.h",
    },
    .{
        .name = "PySequence_InPlaceRepeat",
        .args = &[_]type{ *anyopaque, isize },
        .returns = *anyopaque,
        .doc = "PySequence_InPlaceRepeat from abstract.h",
    },
    .{
        .name = "PyMapping_Check",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyMapping_Check from abstract.h",
    },
    .{
        .name = "PyMapping_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyMapping_Size from abstract.h",
    },
    .{
        .name = "PyMapping_Length",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyMapping_Length from abstract.h",
    },
    .{
        .name = "PyMapping_HasKeyString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = c_int,
        .doc = "PyMapping_HasKeyString from abstract.h",
    },
    .{
        .name = "PyMapping_HasKey",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyMapping_HasKey from abstract.h",
    },
    .{
        .name = "PyMapping_Keys",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyMapping_Keys from abstract.h",
    },
    .{
        .name = "PyMapping_Values",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyMapping_Values from abstract.h",
    },
    .{
        .name = "PyMapping_Items",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyMapping_Items from abstract.h",
    },
    .{
        .name = "PyObject_IsInstance",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_IsInstance from abstract.h",
    },
    .{
        .name = "PyObject_IsSubclass",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyObject_IsSubclass from abstract.h",
    },
};

/// ============================================================================
/// BYTES (8 functions)
/// ============================================================================

pub const BYTES_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyBytes_FromStringAndSize",
        .args = &[_]type{ *const u8, isize },
        .returns = *anyopaque,
        .doc = "PyBytes_FromStringAndSize from bytesobject.h",
    },
    .{
        .name = "PyBytes_FromString",
        .args = &[_]type{ *const u8 },
        .returns = *anyopaque,
        .doc = "PyBytes_FromString from bytesobject.h",
    },
    .{
        .name = "PyBytes_FromObject",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyBytes_FromObject from bytesobject.h",
    },
    .{
        .name = "PyBytes_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyBytes_Size from bytesobject.h",
    },
    .{
        .name = "PyBytes_AsString",
        .args = &[_]type{ *anyopaque },
        .returns = *u8,
        .doc = "PyBytes_AsString from bytesobject.h",
    },
    .{
        .name = "PyBytes_Repr",
        .args = &[_]type{ *anyopaque, c_int },
        .returns = *anyopaque,
        .doc = "PyBytes_Repr from bytesobject.h",
    },
    .{
        .name = "PyBytes_Concat",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyBytes_Concat from bytesobject.h",
    },
    .{
        .name = "PyBytes_ConcatAndDel",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyBytes_ConcatAndDel from bytesobject.h",
    },
};

/// ============================================================================
/// DICT (17 functions)
/// ============================================================================

pub const DICT_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyDict_New",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyDict_New from dictobject.h",
    },
    .{
        .name = "PyDict_GetItem",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyDict_GetItem from dictobject.h",
    },
    .{
        .name = "PyDict_GetItemWithError",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyDict_GetItemWithError from dictobject.h",
    },
    .{
        .name = "PyDict_SetItem",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyDict_SetItem from dictobject.h",
    },
    .{
        .name = "PyDict_DelItem",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyDict_DelItem from dictobject.h",
    },
    .{
        .name = "PyDict_Clear",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyDict_Clear from dictobject.h",
    },
    .{
        .name = "PyDict_Keys",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyDict_Keys from dictobject.h",
    },
    .{
        .name = "PyDict_Values",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyDict_Values from dictobject.h",
    },
    .{
        .name = "PyDict_Items",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyDict_Items from dictobject.h",
    },
    .{
        .name = "PyDict_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyDict_Size from dictobject.h",
    },
    .{
        .name = "PyDict_Copy",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyDict_Copy from dictobject.h",
    },
    .{
        .name = "PyDict_Contains",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyDict_Contains from dictobject.h",
    },
    .{
        .name = "PyDict_Update",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyDict_Update from dictobject.h",
    },
    .{
        .name = "PyDict_GetItemString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = *anyopaque,
        .doc = "PyDict_GetItemString from dictobject.h",
    },
    .{
        .name = "PyDict_SetItemString",
        .args = &[_]type{ *anyopaque, *const u8, *anyopaque },
        .returns = c_int,
        .doc = "PyDict_SetItemString from dictobject.h",
    },
    .{
        .name = "PyDict_DelItemString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = c_int,
        .doc = "PyDict_DelItemString from dictobject.h",
    },
    .{
        .name = "PyObject_GenericGetDict",
        .args = &[_]type{ *anyopaque, *void },
        .returns = *anyopaque,
        .doc = "PyObject_GenericGetDict from dictobject.h",
    },
};

/// ============================================================================
/// FLOAT (6 functions)
/// ============================================================================

pub const FLOAT_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyFloat_GetMax",
        .args = &[_]type{  },
        .returns = f64,
        .doc = "PyFloat_GetMax from floatobject.h",
    },
    .{
        .name = "PyFloat_GetMin",
        .args = &[_]type{  },
        .returns = f64,
        .doc = "PyFloat_GetMin from floatobject.h",
    },
    .{
        .name = "PyFloat_GetInfo",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyFloat_GetInfo from floatobject.h",
    },
    .{
        .name = "PyFloat_FromString",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyFloat_FromString from floatobject.h",
    },
    .{
        .name = "PyFloat_FromDouble",
        .args = &[_]type{ f64 },
        .returns = *anyopaque,
        .doc = "PyFloat_FromDouble from floatobject.h",
    },
    .{
        .name = "PyFloat_AsDouble",
        .args = &[_]type{ *anyopaque },
        .returns = f64,
        .doc = "PyFloat_AsDouble from floatobject.h",
    },
};

/// ============================================================================
/// IMPORT (7 functions)
/// ============================================================================

pub const IMPORT_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyImport_GetMagicNumber",
        .args = &[_]type{  },
        .returns = c_long,
        .doc = "PyImport_GetMagicNumber from import.h",
    },
    .{
        .name = "PyImport_GetMagicTag",
        .args = &[_]type{  },
        .returns = *const u8,
        .doc = "PyImport_GetMagicTag from import.h",
    },
    .{
        .name = "PyImport_GetModuleDict",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyImport_GetModuleDict from import.h",
    },
    .{
        .name = "PyImport_GetModule",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyImport_GetModule from import.h",
    },
    .{
        .name = "PyImport_GetImporter",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyImport_GetImporter from import.h",
    },
    .{
        .name = "PyImport_Import",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyImport_Import from import.h",
    },
    .{
        .name = "PyImport_ReloadModule",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyImport_ReloadModule from import.h",
    },
};

/// ============================================================================
/// LIST (11 functions)
/// ============================================================================

pub const LIST_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyList_New",
        .args = &[_]type{ isize },
        .returns = *anyopaque,
        .doc = "PyList_New from listobject.h",
    },
    .{
        .name = "PyList_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyList_Size from listobject.h",
    },
    .{
        .name = "PyList_GetItem",
        .args = &[_]type{ *anyopaque, isize },
        .returns = *anyopaque,
        .doc = "PyList_GetItem from listobject.h",
    },
    .{
        .name = "PyList_SetItem",
        .args = &[_]type{ *anyopaque, isize, *anyopaque },
        .returns = c_int,
        .doc = "PyList_SetItem from listobject.h",
    },
    .{
        .name = "PyList_Insert",
        .args = &[_]type{ *anyopaque, isize, *anyopaque },
        .returns = c_int,
        .doc = "PyList_Insert from listobject.h",
    },
    .{
        .name = "PyList_Append",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyList_Append from listobject.h",
    },
    .{
        .name = "PyList_GetSlice",
        .args = &[_]type{ *anyopaque, isize, isize },
        .returns = *anyopaque,
        .doc = "PyList_GetSlice from listobject.h",
    },
    .{
        .name = "PyList_SetSlice",
        .args = &[_]type{ *anyopaque, isize, isize, *anyopaque },
        .returns = c_int,
        .doc = "PyList_SetSlice from listobject.h",
    },
    .{
        .name = "PyList_Sort",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyList_Sort from listobject.h",
    },
    .{
        .name = "PyList_Reverse",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyList_Reverse from listobject.h",
    },
    .{
        .name = "PyList_AsTuple",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyList_AsTuple from listobject.h",
    },
};

/// ============================================================================
/// LONG (24 functions)
/// ============================================================================

pub const LONG_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyLong_FromLong",
        .args = &[_]type{ c_long },
        .returns = *anyopaque,
        .doc = "PyLong_FromLong from longobject.h",
    },
    .{
        .name = "PyLong_FromUnsignedLong",
        .args = &[_]type{ anyopaque },
        .returns = *anyopaque,
        .doc = "PyLong_FromUnsignedLong from longobject.h",
    },
    .{
        .name = "PyLong_FromSize_t",
        .args = &[_]type{ usize },
        .returns = *anyopaque,
        .doc = "PyLong_FromSize_t from longobject.h",
    },
    .{
        .name = "PyLong_FromSsize_t",
        .args = &[_]type{ isize },
        .returns = *anyopaque,
        .doc = "PyLong_FromSsize_t from longobject.h",
    },
    .{
        .name = "PyLong_FromDouble",
        .args = &[_]type{ f64 },
        .returns = *anyopaque,
        .doc = "PyLong_FromDouble from longobject.h",
    },
    .{
        .name = "PyLong_AsLong",
        .args = &[_]type{ *anyopaque },
        .returns = c_long,
        .doc = "PyLong_AsLong from longobject.h",
    },
    .{
        .name = "PyLong_AsLongAndOverflow",
        .args = &[_]type{ *anyopaque, *c_int },
        .returns = c_long,
        .doc = "PyLong_AsLongAndOverflow from longobject.h",
    },
    .{
        .name = "PyLong_AsSsize_t",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyLong_AsSsize_t from longobject.h",
    },
    .{
        .name = "PyLong_AsSize_t",
        .args = &[_]type{ *anyopaque },
        .returns = usize,
        .doc = "PyLong_AsSize_t from longobject.h",
    },
    .{
        .name = "PyLong_AsUnsignedLong",
        .args = &[_]type{ *anyopaque },
        .returns = c_ulong,
        .doc = "PyLong_AsUnsignedLong from longobject.h",
    },
    .{
        .name = "PyLong_AsUnsignedLongMask",
        .args = &[_]type{ *anyopaque },
        .returns = c_ulong,
        .doc = "PyLong_AsUnsignedLongMask from longobject.h",
    },
    .{
        .name = "PyLong_GetInfo",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyLong_GetInfo from longobject.h",
    },
    .{
        .name = "PyLong_AsDouble",
        .args = &[_]type{ *anyopaque },
        .returns = f64,
        .doc = "PyLong_AsDouble from longobject.h",
    },
    .{
        .name = "PyLong_FromVoidPtr",
        .args = &[_]type{ *void },
        .returns = *anyopaque,
        .doc = "PyLong_FromVoidPtr from longobject.h",
    },
    .{
        .name = "PyLong_AsVoidPtr",
        .args = &[_]type{ *anyopaque },
        .returns = *void,
        .doc = "PyLong_AsVoidPtr from longobject.h",
    },
    .{
        .name = "PyLong_FromLongLong",
        .args = &[_]type{ c_long },
        .returns = *anyopaque,
        .doc = "PyLong_FromLongLong from longobject.h",
    },
    .{
        .name = "PyLong_FromUnsignedLongLong",
        .args = &[_]type{ c_ulong },
        .returns = *anyopaque,
        .doc = "PyLong_FromUnsignedLongLong from longobject.h",
    },
    .{
        .name = "PyLong_AsLongLong",
        .args = &[_]type{ *anyopaque },
        .returns = c_longlong,
        .doc = "PyLong_AsLongLong from longobject.h",
    },
    .{
        .name = "PyLong_AsUnsignedLongLong",
        .args = &[_]type{ *anyopaque },
        .returns = anyopaque,
        .doc = "PyLong_AsUnsignedLongLong from longobject.h",
    },
    .{
        .name = "PyLong_AsUnsignedLongLongMask",
        .args = &[_]type{ *anyopaque },
        .returns = anyopaque,
        .doc = "PyLong_AsUnsignedLongLongMask from longobject.h",
    },
    .{
        .name = "PyLong_AsLongLongAndOverflow",
        .args = &[_]type{ *anyopaque, *c_int },
        .returns = c_longlong,
        .doc = "PyLong_AsLongLongAndOverflow from longobject.h",
    },
    .{
        .name = "PyLong_FromString",
        .args = &[_]type{ *const u8, *u8, c_int },
        .returns = *anyopaque,
        .doc = "PyLong_FromString from longobject.h",
    },
    .{
        .name = "PyOS_strtoul",
        .args = &[_]type{ *const u8, *u8, c_int },
        .returns = c_ulong,
        .doc = "PyOS_strtoul from longobject.h",
    },
    .{
        .name = "PyOS_strtol",
        .args = &[_]type{ *const u8, *u8, c_int },
        .returns = c_long,
        .doc = "PyOS_strtol from longobject.h",
    },
};

/// ============================================================================
/// METHOD (5 functions)
/// ============================================================================

pub const METHOD_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyCFunction_GetFunction",
        .args = &[_]type{ *anyopaque },
        .returns = anyopaque,
        .doc = "PyCFunction_GetFunction from methodobject.h",
    },
    .{
        .name = "PyCFunction_GetSelf",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyCFunction_GetSelf from methodobject.h",
    },
    .{
        .name = "PyCFunction_GetFlags",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyCFunction_GetFlags from methodobject.h",
    },
    .{
        .name = "PyCFunction_Call",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyCFunction_Call from methodobject.h",
    },
    .{
        .name = "PyCFunction_New",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = *anyopaque,
        .doc = "PyCFunction_New from methodobject.h",
    },
};

/// ============================================================================
/// MODSUPPORT (17 functions)
/// ============================================================================

pub const MODSUPPORT_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyArg_Parse",
        .args = &[_]type{ *anyopaque, *const u8, anyopaque },
        .returns = c_int,
        .doc = "PyArg_Parse from modsupport.h",
    },
    .{
        .name = "PyArg_ParseTuple",
        .args = &[_]type{ *anyopaque, *const u8, anyopaque },
        .returns = c_int,
        .doc = "PyArg_ParseTuple from modsupport.h",
    },
    .{
        .name = "PyArg_VaParse",
        .args = &[_]type{ *anyopaque, *const u8, anyopaque },
        .returns = c_int,
        .doc = "PyArg_VaParse from modsupport.h",
    },
    .{
        .name = "PyArg_ValidateKeywordArguments",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyArg_ValidateKeywordArguments from modsupport.h",
    },
    .{
        .name = "PyArg_UnpackTuple",
        .args = &[_]type{ *anyopaque, *const u8, isize, isize, anyopaque },
        .returns = c_int,
        .doc = "PyArg_UnpackTuple from modsupport.h",
    },
    .{
        .name = "Py_BuildValue",
        .args = &[_]type{ *const u8, anyopaque },
        .returns = *anyopaque,
        .doc = "Py_BuildValue from modsupport.h",
    },
    .{
        .name = "_Py_BuildValue_SizeT",
        .args = &[_]type{ *const u8, anyopaque },
        .returns = *anyopaque,
        .doc = "_Py_BuildValue_SizeT from modsupport.h",
    },
    .{
        .name = "Py_VaBuildValue",
        .args = &[_]type{ *const u8, anyopaque },
        .returns = *anyopaque,
        .doc = "Py_VaBuildValue from modsupport.h",
    },
    .{
        .name = "PyModule_AddObjectRef",
        .args = &[_]type{ *anyopaque, *const u8, *anyopaque },
        .returns = c_int,
        .doc = "PyModule_AddObjectRef from modsupport.h",
    },
    .{
        .name = "PyModule_AddObject",
        .args = &[_]type{ *anyopaque, *const u8, *anyopaque },
        .returns = c_int,
        .doc = "PyModule_AddObject from modsupport.h",
    },
    .{
        .name = "PyModule_AddIntConstant",
        .args = &[_]type{ *anyopaque, *const u8, c_long },
        .returns = c_int,
        .doc = "PyModule_AddIntConstant from modsupport.h",
    },
    .{
        .name = "PyModule_AddStringConstant",
        .args = &[_]type{ *anyopaque, *const u8, *const u8 },
        .returns = c_int,
        .doc = "PyModule_AddStringConstant from modsupport.h",
    },
    .{
        .name = "PyModule_AddType",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyModule_AddType from modsupport.h",
    },
    .{
        .name = "PyModule_SetDocString",
        .args = &[_]type{ *anyopaque, *const u8 },
        .returns = c_int,
        .doc = "PyModule_SetDocString from modsupport.h",
    },
    .{
        .name = "PyModule_AddFunctions",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyModule_AddFunctions from modsupport.h",
    },
    .{
        .name = "PyModule_ExecDef",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyModule_ExecDef from modsupport.h",
    },
    .{
        .name = "PyModule_Create2",
        .args = &[_]type{ *anyopaque, c_int },
        .returns = *anyopaque,
        .doc = "PyModule_Create2 from modsupport.h",
    },
};

/// ============================================================================
/// MODULE (11 functions)
/// ============================================================================

pub const MODULE_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyModule_GetDict",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyModule_GetDict from moduleobject.h",
    },
    .{
        .name = "PyModule_GetNameObject",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyModule_GetNameObject from moduleobject.h",
    },
    .{
        .name = "PyModule_GetName",
        .args = &[_]type{ *anyopaque },
        .returns = *const u8,
        .doc = "PyModule_GetName from moduleobject.h",
    },
    .{
        .name = "PyModule_GetFilename",
        .args = &[_]type{ *anyopaque },
        .returns = *const u8,
        .doc = "PyModule_GetFilename from moduleobject.h",
    },
    .{
        .name = "PyModule_GetFilenameObject",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyModule_GetFilenameObject from moduleobject.h",
    },
    .{
        .name = "_PyModule_Clear",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "_PyModule_Clear from moduleobject.h",
    },
    .{
        .name = "_PyModule_ClearDict",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "_PyModule_ClearDict from moduleobject.h",
    },
    .{
        .name = "_PyModuleSpec_IsInitializing",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "_PyModuleSpec_IsInitializing from moduleobject.h",
    },
    .{
        .name = "PyModule_GetDef",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyModule_GetDef from moduleobject.h",
    },
    .{
        .name = "PyModule_GetState",
        .args = &[_]type{ *anyopaque },
        .returns = *void,
        .doc = "PyModule_GetState from moduleobject.h",
    },
    .{
        .name = "PyModuleDef_Init",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyModuleDef_Init from moduleobject.h",
    },
};

/// ============================================================================
/// PYERRORS (55 functions)
/// ============================================================================

pub const PYERRORS_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyErr_SetNone",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyErr_SetNone from pyerrors.h",
    },
    .{
        .name = "PyErr_SetObject",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyErr_SetObject from pyerrors.h",
    },
    .{
        .name = "PyErr_Occurred",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyErr_Occurred from pyerrors.h",
    },
    .{
        .name = "PyErr_Clear",
        .args = &[_]type{  },
        .returns = void,
        .doc = "PyErr_Clear from pyerrors.h",
    },
    .{
        .name = "PyErr_Fetch",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyErr_Fetch from pyerrors.h",
    },
    .{
        .name = "PyErr_Restore",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyErr_Restore from pyerrors.h",
    },
    .{
        .name = "PyErr_GetRaisedException",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyErr_GetRaisedException from pyerrors.h",
    },
    .{
        .name = "PyErr_SetRaisedException",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyErr_SetRaisedException from pyerrors.h",
    },
    .{
        .name = "PyErr_GetHandledException",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyErr_GetHandledException from pyerrors.h",
    },
    .{
        .name = "PyErr_SetHandledException",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyErr_SetHandledException from pyerrors.h",
    },
    .{
        .name = "PyErr_GetExcInfo",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyErr_GetExcInfo from pyerrors.h",
    },
    .{
        .name = "PyErr_SetExcInfo",
        .args = &[_]type{ *anyopaque, *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyErr_SetExcInfo from pyerrors.h",
    },
    .{
        .name = "PyErr_GivenExceptionMatches",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyErr_GivenExceptionMatches from pyerrors.h",
    },
    .{
        .name = "PyErr_ExceptionMatches",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyErr_ExceptionMatches from pyerrors.h",
    },
    .{
        .name = "PyErr_NormalizeException",
        .args = &[_]type{ **anyopaque, **anyopaque, **anyopaque },
        .returns = void,
        .doc = "PyErr_NormalizeException from pyerrors.h",
    },
    .{
        .name = "PyException_SetTraceback",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = c_int,
        .doc = "PyException_SetTraceback from pyerrors.h",
    },
    .{
        .name = "PyException_GetTraceback",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyException_GetTraceback from pyerrors.h",
    },
    .{
        .name = "PyException_GetCause",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyException_GetCause from pyerrors.h",
    },
    .{
        .name = "PyException_SetCause",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyException_SetCause from pyerrors.h",
    },
    .{
        .name = "PyException_GetContext",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyException_GetContext from pyerrors.h",
    },
    .{
        .name = "PyException_SetContext",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyException_SetContext from pyerrors.h",
    },
    .{
        .name = "PyException_GetArgs",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyException_GetArgs from pyerrors.h",
    },
    .{
        .name = "PyException_SetArgs",
        .args = &[_]type{ *anyopaque, *anyopaque },
        .returns = void,
        .doc = "PyException_SetArgs from pyerrors.h",
    },
    .{
        .name = "PyExceptionClass_Name",
        .args = &[_]type{ *anyopaque },
        .returns = *const u8,
        .doc = "PyExceptionClass_Name from pyerrors.h",
    },
    .{
        .name = "PyErr_BadArgument",
        .args = &[_]type{  },
        .returns = c_int,
        .doc = "PyErr_BadArgument from pyerrors.h",
    },
    .{
        .name = "PyErr_NoMemory",
        .args = &[_]type{  },
        .returns = *anyopaque,
        .doc = "PyErr_NoMemory from pyerrors.h",
    },
    .{
        .name = "PyErr_SetFromErrno",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyErr_SetFromErrno from pyerrors.h",
    },
    .{
        .name = "PyErr_SetFromWindowsErr",
        .args = &[_]type{ c_int },
        .returns = *anyopaque,
        .doc = "PyErr_SetFromWindowsErr from pyerrors.h",
    },
    .{
        .name = "PyErr_SetExcFromWindowsErr",
        .args = &[_]type{ *anyopaque, c_int },
        .returns = *anyopaque,
        .doc = "PyErr_SetExcFromWindowsErr from pyerrors.h",
    },
    .{
        .name = "PyErr_BadInternalCall",
        .args = &[_]type{  },
        .returns = void,
        .doc = "PyErr_BadInternalCall from pyerrors.h",
    },
    .{
        .name = "_PyErr_BadInternalCall",
        .args = &[_]type{ *const u8, c_int },
        .returns = void,
        .doc = "_PyErr_BadInternalCall from pyerrors.h",
    },
    .{
        .name = "PyErr_WriteUnraisable",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyErr_WriteUnraisable from pyerrors.h",
    },
    .{
        .name = "PyErr_CheckSignals",
        .args = &[_]type{  },
        .returns = c_int,
        .doc = "PyErr_CheckSignals from pyerrors.h",
    },
    .{
        .name = "PyErr_SetInterrupt",
        .args = &[_]type{  },
        .returns = void,
        .doc = "PyErr_SetInterrupt from pyerrors.h",
    },
    .{
        .name = "PyErr_SetInterruptEx",
        .args = &[_]type{ c_int },
        .returns = c_int,
        .doc = "PyErr_SetInterruptEx from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_GetEncoding",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeEncodeError_GetEncoding from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_GetEncoding",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeDecodeError_GetEncoding from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_GetObject",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeEncodeError_GetObject from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_GetObject",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeDecodeError_GetObject from pyerrors.h",
    },
    .{
        .name = "PyUnicodeTranslateError_GetObject",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeTranslateError_GetObject from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_GetStart",
        .args = &[_]type{ *anyopaque, *isize },
        .returns = c_int,
        .doc = "PyUnicodeEncodeError_GetStart from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_GetStart",
        .args = &[_]type{ *anyopaque, *isize },
        .returns = c_int,
        .doc = "PyUnicodeDecodeError_GetStart from pyerrors.h",
    },
    .{
        .name = "PyUnicodeTranslateError_GetStart",
        .args = &[_]type{ *anyopaque, *isize },
        .returns = c_int,
        .doc = "PyUnicodeTranslateError_GetStart from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_SetStart",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PyUnicodeEncodeError_SetStart from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_SetStart",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PyUnicodeDecodeError_SetStart from pyerrors.h",
    },
    .{
        .name = "PyUnicodeTranslateError_SetStart",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PyUnicodeTranslateError_SetStart from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_GetEnd",
        .args = &[_]type{ *anyopaque, *isize },
        .returns = c_int,
        .doc = "PyUnicodeEncodeError_GetEnd from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_GetEnd",
        .args = &[_]type{ *anyopaque, *isize },
        .returns = c_int,
        .doc = "PyUnicodeDecodeError_GetEnd from pyerrors.h",
    },
    .{
        .name = "PyUnicodeTranslateError_GetEnd",
        .args = &[_]type{ *anyopaque, *isize },
        .returns = c_int,
        .doc = "PyUnicodeTranslateError_GetEnd from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_SetEnd",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PyUnicodeEncodeError_SetEnd from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_SetEnd",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PyUnicodeDecodeError_SetEnd from pyerrors.h",
    },
    .{
        .name = "PyUnicodeTranslateError_SetEnd",
        .args = &[_]type{ *anyopaque, isize },
        .returns = c_int,
        .doc = "PyUnicodeTranslateError_SetEnd from pyerrors.h",
    },
    .{
        .name = "PyUnicodeEncodeError_GetReason",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeEncodeError_GetReason from pyerrors.h",
    },
    .{
        .name = "PyUnicodeDecodeError_GetReason",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeDecodeError_GetReason from pyerrors.h",
    },
    .{
        .name = "PyUnicodeTranslateError_GetReason",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicodeTranslateError_GetReason from pyerrors.h",
    },
};

/// ============================================================================
/// TUPLE (6 functions)
/// ============================================================================

pub const TUPLE_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyTuple_New",
        .args = &[_]type{ isize },
        .returns = *anyopaque,
        .doc = "PyTuple_New from tupleobject.h",
    },
    .{
        .name = "PyTuple_Size",
        .args = &[_]type{ *anyopaque },
        .returns = isize,
        .doc = "PyTuple_Size from tupleobject.h",
    },
    .{
        .name = "PyTuple_GetItem",
        .args = &[_]type{ *anyopaque, isize },
        .returns = *anyopaque,
        .doc = "PyTuple_GetItem from tupleobject.h",
    },
    .{
        .name = "PyTuple_SetItem",
        .args = &[_]type{ *anyopaque, isize, *anyopaque },
        .returns = c_int,
        .doc = "PyTuple_SetItem from tupleobject.h",
    },
    .{
        .name = "PyTuple_GetSlice",
        .args = &[_]type{ *anyopaque, isize, isize },
        .returns = *anyopaque,
        .doc = "PyTuple_GetSlice from tupleobject.h",
    },
    .{
        .name = "PyTuple_Pack",
        .args = &[_]type{ isize, anyopaque },
        .returns = *anyopaque,
        .doc = "PyTuple_Pack from tupleobject.h",
    },
};

/// ============================================================================
/// UNICODE (7 functions)
/// ============================================================================

pub const UNICODE_SPECS = [_]CPythonAPISpec{
    .{
        .name = "PyUnicode_AsUCS4Copy",
        .args = &[_]type{ *anyopaque },
        .returns = *anyopaque,
        .doc = "PyUnicode_AsUCS4Copy from unicodeobject.h",
    },
    .{
        .name = "PyUnicode_InternInPlace",
        .args = &[_]type{ *anyopaque },
        .returns = void,
        .doc = "PyUnicode_InternInPlace from unicodeobject.h",
    },
    .{
        .name = "PyUnicode_FromOrdinal",
        .args = &[_]type{ c_int },
        .returns = *anyopaque,
        .doc = "PyUnicode_FromOrdinal from unicodeobject.h",
    },
    .{
        .name = "PyUnicode_GetDefaultEncoding",
        .args = &[_]type{  },
        .returns = *const u8,
        .doc = "PyUnicode_GetDefaultEncoding from unicodeobject.h",
    },
    .{
        .name = "PyUnicode_FSConverter",
        .args = &[_]type{ *anyopaque, *void },
        .returns = c_int,
        .doc = "PyUnicode_FSConverter from unicodeobject.h",
    },
    .{
        .name = "PyUnicode_FSDecoder",
        .args = &[_]type{ *anyopaque, *void },
        .returns = c_int,
        .doc = "PyUnicode_FSDecoder from unicodeobject.h",
    },
    .{
        .name = "PyUnicode_IsIdentifier",
        .args = &[_]type{ *anyopaque },
        .returns = c_int,
        .doc = "PyUnicode_IsIdentifier from unicodeobject.h",
    },
};

/// ============================================================================
/// SUMMARY
/// ============================================================================

pub const TOTAL_FUNCTIONS = 309;

pub const ALL_SPECS = blk: {
    var specs: [TOTAL_FUNCTIONS]CPythonAPISpec = undefined;
    var idx: usize = 0;

    for (_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (ABSTRACT_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (BYTES_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (DICT_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (FLOAT_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (IMPORT_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (LIST_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (LONG_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (METHOD_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (MODSUPPORT_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (MODULE_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (PYERRORS_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (TUPLE_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    for (UNICODE_SPECS) |spec| {
        specs[idx] = spec;
        idx += 1;
    }

    break :blk specs;
};

// Import CPythonAPISpec type
const CPythonAPISpec = @import("cpython_api_generator.zig").CPythonAPISpec;
