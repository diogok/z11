const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const x11 = b.addModule("x11", .{ .root_source_file = b.path("src/x11.zig") });

    const demo = b.addExecutable(.{
        .name = "demo",
        .target = target,
        .optimize = optimize,
        .strip = optimize == .ReleaseSmall,
        .link_libc = optimize == .Debug,
        .root_source_file = b.path("src/demo.zig"),
    });
    demo.root_module.addImport("x11", x11);

    b.installArtifact(demo);

    const run_cmd = b.addRunArtifact(demo);
    const run_step = b.step("run", "Run demo");
    run_step.dependOn(&run_cmd.step);

    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/x11.zig"),
    });

    const run_tests = b.addRunArtifact(tests);
    const run_tests_step = b.step("test", "Run tests");
    run_tests_step.dependOn(&run_tests.step);

    const install_docs = b.addInstallDirectory(.{
        .source_dir = tests.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Install documentation");
    docs_step.dependOn(&install_docs.step);
}
