/// Function and class definition code generation - re-exports from submodules
const generators = @import("functions/generators.zig");

pub const genFunctionDef = generators.genFunctionDef;
pub const genClassDef = generators.genClassDef;
