/* Python.h - Unified CPython C API Header
 *
 * This is the main header file that C extensions #include
 * Provides all CPython C API functions implemented in Zig
 *
 * Usage from C extension:
 *   #include <Python.h>
 *
 *   PyObject* my_function(PyObject* self, PyObject* args) {
 *       long a, b;
 *       if (!PyArg_ParseTuple(args, "ll", &a, &b)) return NULL;
 *       return PyLong_FromLong(a + b);
 *   }
 */

#ifndef Py_PYTHON_H
#define Py_PYTHON_H

#include <stddef.h>  /* size_t */
#include <stdint.h>  /* int64_t, etc */

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * CORE TYPES
 * ============================================================================ */

/* Forward declarations */
typedef struct _object PyObject;
typedef struct _typeobject PyTypeObject;

/* Basic Python object structure */
typedef struct _object {
    int64_t ob_refcnt;
    PyTypeObject *ob_type;
} PyObject;

/* Variable-size object (lists, tuples, strings) */
typedef struct {
    PyObject ob_base;
    int64_t ob_size;
} PyVarObject;

/* Common return values */
#define Py_RETURN_NONE return Py_None
#define Py_RETURN_TRUE return Py_True
#define Py_RETURN_FALSE return Py_False

/* ============================================================================
 * REFERENCE COUNTING
 * ============================================================================ */

/* Increment reference count */
extern void Py_INCREF(void *op);

/* Decrement reference count, destroy if zero */
extern void Py_DECREF(void *op);

/* Null-safe increment */
extern void Py_XINCREF(void *op);

/* Null-safe decrement */
extern void Py_XDECREF(void *op);

/* ============================================================================
 * MEMORY ALLOCATORS
 * ============================================================================ */

/* General memory allocation */
extern void* PyMem_Malloc(size_t size);
extern void* PyMem_Calloc(size_t nelem, size_t elsize);
extern void* PyMem_Realloc(void *ptr, size_t size);
extern void PyMem_Free(void *ptr);

/* Object-specific allocation (optimized for small objects) */
extern void* PyObject_Malloc(size_t size);
extern void PyObject_Free(void *ptr);

/* ============================================================================
 * TYPE CONVERSIONS - PyLong (Integer)
 * ============================================================================ */

extern PyObject* PyLong_FromLong(long value);
extern PyObject* PyLong_FromUnsignedLong(unsigned long value);
extern PyObject* PyLong_FromLongLong(long long value);
extern PyObject* PyLong_FromSize_t(size_t value);

extern long PyLong_AsLong(PyObject *obj);
extern long long PyLong_AsLongLong(PyObject *obj);
extern size_t PyLong_AsSize_t(PyObject *obj);

extern int PyLong_Check(PyObject *obj);

/* ============================================================================
 * TYPE CONVERSIONS - PyFloat
 * ============================================================================ */

extern PyObject* PyFloat_FromDouble(double value);
extern double PyFloat_AsDouble(PyObject *obj);
extern int PyFloat_Check(PyObject *obj);
extern int PyFloat_CheckExact(PyObject *obj);

/* ============================================================================
 * PYTUPLE OPERATIONS
 * ============================================================================ */

extern PyObject* PyTuple_New(int64_t size);
extern int64_t PyTuple_Size(PyObject *obj);
extern PyObject* PyTuple_GetItem(PyObject *obj, int64_t index);
extern int PyTuple_SetItem(PyObject *obj, int64_t index, PyObject *item);
extern int PyTuple_Check(PyObject *obj);

/* ============================================================================
 * PYLIST OPERATIONS
 * ============================================================================ */

extern PyObject* PyList_New(int64_t size);
extern int64_t PyList_Size(PyObject *obj);
extern PyObject* PyList_GetItem(PyObject *obj, int64_t index);
extern int PyList_SetItem(PyObject *obj, int64_t index, PyObject *item);
extern int PyList_Append(PyObject *obj, PyObject *item);
extern int PyList_Check(PyObject *obj);

/* ============================================================================
 * ARGUMENT PARSING (CRITICAL!)
 * ============================================================================ */

/* Parse tuple into C variables
 * Format codes:
 *   s - string (char**)
 *   i - int (int*)
 *   l - long (long*)
 *   L - long long (long long*)
 *   d - double (double*)
 *   f - float (float*)
 *   O - PyObject* (PyObject**)
 *   | - optional marker
 */
extern int PyArg_ParseTuple(PyObject *args, const char *format, ...);
extern int PyArg_ParseTupleAndKeywords(PyObject *args, PyObject *kwargs,
                                        const char *format, char **keywords, ...);

/* Build Python value from C values (inverse of ParseTuple) */
extern PyObject* Py_BuildValue(const char *format, ...);

/* ============================================================================
 * TYPE CHECKING MACROS
 * ============================================================================ */

/* Get object type */
#define Py_TYPE(op) (((PyObject*)(op))->ob_type)

/* Get reference count */
#define Py_REFCNT(op) (((PyObject*)(op))->ob_refcnt)

/* Get size for variable-size objects */
#define Py_SIZE(op) (((PyVarObject*)(op))->ob_size)

/* ============================================================================
 * MODULE/METHOD DEFINITIONS
 * ============================================================================ */

/* Method calling flags */
#define METH_VARARGS  0x0001
#define METH_KEYWORDS 0x0002
#define METH_NOARGS   0x0004
#define METH_O        0x0008

/* Method definition structure */
typedef PyObject *(*PyCFunction)(PyObject *, PyObject *);

typedef struct PyMethodDef {
    const char *ml_name;   /* Method name */
    PyCFunction ml_meth;   /* C function pointer */
    int ml_flags;          /* Calling convention flags */
    const char *ml_doc;    /* Docstring */
} PyMethodDef;

/* ============================================================================
 * COMMON SINGLETONS (TODO: Implement)
 * ============================================================================ */

/* These should be implemented as global singletons */
extern PyObject *Py_None;
extern PyObject *Py_True;
extern PyObject *Py_False;

#ifdef __cplusplus
}
#endif

#endif /* !Py_PYTHON_H */
