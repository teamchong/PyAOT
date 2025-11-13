const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Test executable for lexer+parser
    const test_exe = b.addExecutable(.{
        .name = "test_pipeline",
        .root_source_file = .{ .path = "test_pipeline.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(test_exe);

    const run_test = b.addRunArtifact(test_exe);
    const test_step = b.step("test-pipeline", "Test lexer and parser");
    test_step.dependOn(&run_test.step);
}
