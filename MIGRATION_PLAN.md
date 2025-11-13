# Zyth Compiler Migration: Python → Zig

## Goal
Single binary `zyth` with zero Python dependency.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  zyth (Zig binary)                                  │
│  ├─ Lexer:    Python source → Tokens               │
│  ├─ Parser:   Tokens → AST                         │
│  ├─ Codegen:  AST → Zig source                     │
│  └─ Compiler: Shell out to `zig build-exe`         │
└─────────────────────────────────────────────────────┘
```

## Directory Structure

```
zyth/
├── src/                      # Zig compiler source (NEW)
│   ├── main.zig             # CLI entry point
│   ├── lexer.zig            # Tokenize Python source
│   ├── parser.zig           # Parse tokens → AST
│   ├── ast.zig              # AST data structures
│   ├── codegen.zig          # Generate Zig code from AST
│   ├── compiler.zig         # Orchestrate compilation
│   └── utils.zig            # String helpers, etc.
│
├── runtime/                  # Runtime library (KEEP)
│   └── src/
│       └── runtime.zig      # PyObject, PyList, etc.
│
├── packages/                 # Python code (DEPRECATE)
│   ├── core/                # Keep temporarily for tests
│   └── cli/                 # DELETE (replaced by src/main.zig)
│
├── build.zig                # Zig build system (NEW)
├── tests/                   # Tests
└── examples/                # Demo programs
```

## Migration Phases

### Phase 0: Current (Python-based)
```bash
zyth app.py
  └─> python -m core.compiler app.py
```
- ✅ Works today
- ❌ Needs Python
- ❌ Slow (200-500ms codegen)

### Phase 1: Zig CLI + Python codegen (BRIDGE)
```bash
zyth app.py
  └─> zig binary (src/main.zig)
      └─> python -m core.compiler --ast-only app.py  # Get AST JSON
      └─> Zig codegen (AST JSON → Zig code)
      └─> zig build-exe output.zig
```
**Goals:**
- Single `zyth` binary
- Still needs Python for parsing
- Zig handles codegen + compilation
- **Effort:** 2-3 days

### Phase 2: tree-sitter parser (OPTIONAL)
```bash
zyth app.py
  └─> tree-sitter-python (C library) → CST
  └─> Convert CST → our AST
  └─> Zig codegen
  └─> zig build-exe
```
**Goals:**
- No Python dependency
- Uses existing C library
- **Effort:** 1 week

### Phase 3: Pure Zig parser (FINAL)
```bash
zyth app.py
  └─> Zig lexer → tokens
  └─> Zig parser → AST
  └─> Zig codegen → Zig source
  └─> zig build-exe
```
**Goals:**
- 100% Zig
- No dependencies
- Full control
- **Effort:** 2-3 weeks

## Implementation Order

1. ✅ **Create structure** (this file)
2. 🔄 **Implement Zig CLI** (src/main.zig)
3. 🔄 **Port codegen to Zig** (src/codegen.zig)
4. ⏳ **Bridge: Python AST → JSON** (temporary)
5. ⏳ **Implement lexer** (src/lexer.zig)
6. ⏳ **Implement parser** (src/parser.zig)
7. ⏳ **Delete Python packages/**

## File Size Targets

| File | Lines | Purpose |
|------|-------|---------|
| main.zig | 100-150 | CLI args, file I/O |
| lexer.zig | 300-400 | Tokenization |
| parser.zig | 600-800 | AST construction |
| ast.zig | 200-300 | AST types |
| codegen.zig | 1500-2000 | Zig code generation |
| compiler.zig | 100-200 | Shell out to zig |

**Total:** ~3000 lines Zig (vs 4540 lines Python currently)

## Performance Targets

| Operation | Python | Zig (target) | Speedup |
|-----------|--------|--------------|---------|
| Lexing | 20ms | 1ms | 20x |
| Parsing | 30ms | 2ms | 15x |
| Codegen | 200ms | 10ms | 20x |
| **Total** | **250ms** | **13ms** | **19x** |

Zig compilation time (~1-2s) dominates, but that's unavoidable.

## Next Steps

Run:
```bash
mkdir -p src
zig init-exe  # Create basic structure
```

Then start implementing Phase 1.
