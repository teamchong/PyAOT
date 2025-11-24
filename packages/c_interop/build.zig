const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create c_interop module
    const c_interop_mod = b.addModule("c_interop", .{
        .root_source_file = b.path("src/registry.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Unit tests
    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/mapper.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const registry_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/registry.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const object_protocol_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cpython_object_protocol.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const unicode_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cpython_unicode.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const test_step = b.step("test", "Run c_interop unit tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
    test_step.dependOn(&b.addRunArtifact(registry_tests).step);
    test_step.dependOn(&b.addRunArtifact(object_protocol_tests).step);
    test_step.dependOn(&b.addRunArtifact(unicode_tests).step);

    _ = c_interop_mod;
}
