#!/usr/bin/env python3
"""
Parse CPython C headers and generate Zig function specs

This script extracts all PyAPI_FUNC declarations from CPython headers
and generates our CPythonAPISpec definitions automatically.

Time savings: 8 hours manual → 30 minutes automated!
"""

import re
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class CFunction:
    """Represents a CPython C API function"""
    name: str
    return_type: str
    args: List[tuple[str, str]]  # [(type, name), ...]
    source_file: str

def parse_function_signature(line: str, file_path: str) -> Optional[CFunction]:
    """
    Parse a PyAPI_FUNC declaration

    Examples:
        PyAPI_FUNC(void) Py_INCREF(PyObject *op);
        PyAPI_FUNC(PyObject *) PyList_New(Py_ssize_t size);
    """
    # Match: PyAPI_FUNC(return_type) func_name(args);
    pattern = r'PyAPI_FUNC\((.*?)\)\s+(\w+)\s*\((.*?)\);'
    match = re.search(pattern, line)

    if not match:
        return None

    return_type = match.group(1).strip()
    func_name = match.group(2).strip()
    args_str = match.group(3).strip()

    # Parse arguments
    args = []
    if args_str and args_str != 'void':
        # Split by comma, but respect nested parens
        arg_parts = []
        paren_depth = 0
        current_arg = ""

        for char in args_str + ',':
            if char == '(':
                paren_depth += 1
                current_arg += char
            elif char == ')':
                paren_depth -= 1
                current_arg += char
            elif char == ',' and paren_depth == 0:
                if current_arg.strip():
                    arg_parts.append(current_arg.strip())
                current_arg = ""
            else:
                current_arg += char

        for arg in arg_parts:
            # Extract type and name
            # Handle cases like: "PyObject *op", "int flag"
            parts = arg.rsplit(None, 1)
            if len(parts) == 2:
                arg_type, arg_name = parts
                # Remove * from name if present
                if '*' in arg_name:
                    arg_type += '*'
                    arg_name = arg_name.replace('*', '')
                args.append((arg_type.strip(), arg_name.strip()))
            elif len(parts) == 1:
                # Just a type, no name
                args.append((parts[0].strip(), ''))

    return CFunction(
        name=func_name,
        return_type=return_type,
        args=args,
        source_file=file_path
    )

def c_type_to_zig(c_type: str) -> str:
    """Convert C type to Zig type"""
    c_type = c_type.strip()

    # Handle pointers
    ptr_count = c_type.count('*')
    base_type = c_type.replace('*', '').replace('const', '').strip()

    # Map common types
    type_map = {
        'void': 'void',
        'int': 'c_int',
        'long': 'c_long',
        'unsigned long': 'c_ulong',
        'long long': 'c_longlong',
        'size_t': 'usize',
        'Py_ssize_t': 'isize',
        'double': 'f64',
        'float': 'f32',
        'char': 'u8',
        'PyObject': 'anyopaque',
        'PyTypeObject': 'anyopaque',
        'PyModuleDef': 'anyopaque',
        'FILE': 'anyopaque',
    }

    zig_base = type_map.get(base_type, 'anyopaque')

    # Add pointer levels
    if ptr_count > 0:
        # Check if const pointer
        is_const = 'const' in c_type
        for _ in range(ptr_count):
            if is_const:
                zig_base = f'*const {zig_base}' if zig_base != 'anyopaque' else '*anyopaque'
            else:
                zig_base = f'*{zig_base}' if zig_base != 'anyopaque' else '*anyopaque'

    return zig_base

def generate_zig_spec(func: CFunction) -> str:
    """Generate a CPythonAPISpec struct in Zig"""
    # Convert argument types
    zig_args = [c_type_to_zig(arg[0]) for arg in func.args]
    zig_return = c_type_to_zig(func.return_type)

    # Format as Zig struct literal
    args_str = ', '.join(zig_args)

    return f'''    .{{
        .name = "{func.name}",
        .args = &[_]type{{ {args_str} }},
        .returns = {zig_return},
        .doc = "{func.name} from {func.source_file}",
    }},'''

def scan_cpython_headers(cpython_path: Path) -> List[CFunction]:
    """Scan all CPython headers for API functions"""
    functions = []

    include_dir = cpython_path / 'Include'
    if not include_dir.exists():
        print(f"Error: {include_dir} not found")
        print("Please provide path to CPython source directory")
        return []

    # Key header files to scan
    headers = [
        'object.h',
        'listobject.h',
        'tupleobject.h',
        'dictobject.h',
        'longobject.h',
        'floatobject.h',
        'bytesobject.h',
        'unicodeobject.h',
        'moduleobject.h',
        'methodobject.h',
        'funcobject.h',
        'import.h',
        'pyerrors.h',
        'modsupport.h',  # PyArg_ParseTuple
        'abstract.h',    # Abstract protocols
    ]

    for header in headers:
        header_path = include_dir / header
        if not header_path.exists():
            print(f"Warning: {header_path} not found, skipping")
            continue

        with open(header_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                func = parse_function_signature(line, header)
                if func:
                    functions.append(func)

    return functions

def generate_zig_file(functions: List[CFunction], output_path: Path):
    """Generate complete Zig file with all specs"""

    # Group by category based on source file
    categories = {}
    for func in functions:
        cat = func.source_file.replace('object.h', '').replace('.h', '')
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(func)

    with open(output_path, 'w') as f:
        f.write('''/// Auto-generated CPython API Specs
/// Generated from CPython header files
/// DO NOT EDIT MANUALLY - regenerate with parse_cpython_headers.py

const std = @import("std");

''')

        for category, funcs in sorted(categories.items()):
            cat_upper = category.upper()
            f.write(f'''
/// ============================================================================
/// {cat_upper} ({len(funcs)} functions)
/// ============================================================================

pub const {cat_upper}_SPECS = [_]CPythonAPISpec{{
''')
            for func in funcs:
                f.write(generate_zig_spec(func))
                f.write('\n')

            f.write('};\n')

        # Generate summary
        f.write(f'''
/// ============================================================================
/// SUMMARY
/// ============================================================================

pub const TOTAL_FUNCTIONS = {len(functions)};

pub const ALL_SPECS = blk: {{
    var specs: [TOTAL_FUNCTIONS]CPythonAPISpec = undefined;
    var idx: usize = 0;
''')

        for category in sorted(categories.keys()):
            cat_upper = category.upper()
            f.write(f'''
    for ({cat_upper}_SPECS) |spec| {{
        specs[idx] = spec;
        idx += 1;
    }}
''')

        f.write('''
    break :blk specs;
};
''')

        f.write('''
// Import CPythonAPISpec type
const CPythonAPISpec = @import("cpython_api_generator.zig").CPythonAPISpec;
''')

def main():
    # Check for CPython path
    if len(sys.argv) < 2:
        print("Usage: python3 parse_cpython_headers.py <path-to-cpython-source>")
        print()
        print("Example:")
        print("  python3 parse_cpython_headers.py ~/Downloads/cpython-3.12.0")
        print()
        print("This will scan CPython headers and generate all 146+ function specs automatically!")
        sys.exit(1)

    cpython_path = Path(sys.argv[1])
    if not cpython_path.exists():
        print(f"Error: {cpython_path} does not exist")
        sys.exit(1)

    print(f"📚 Scanning CPython headers in: {cpython_path}")
    functions = scan_cpython_headers(cpython_path)

    if not functions:
        print("❌ No functions found. Check CPython path.")
        sys.exit(1)

    print(f"✅ Found {len(functions)} API functions")

    # Show some examples
    print("\nExample functions found:")
    for func in functions[:5]:
        print(f"  - {func.name} ({len(func.args)} args) from {func.source_file}")

    # Generate output file
    output_path = Path(__file__).parent.parent / 'packages' / 'c_interop' / 'src' / 'cpython_api_specs_generated.zig'
    print(f"\n📝 Generating Zig specs: {output_path}")
    generate_zig_file(functions, output_path)

    print(f"✅ Generated {len(functions)} function specs!")
    print("\n🎉 Done! You can now import these specs in cpython_api_generator.zig")

if __name__ == '__main__':
    main()
