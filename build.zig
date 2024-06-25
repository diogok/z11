const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const x11 = b.addModule("x11", .{ .root_source_file = b.path("src/x11.zig") });

    {
        const exe = b.addExecutable(.{
            .name = "demo",
            .target = target,
            .optimize = optimize,
            .strip = optimize == .ReleaseSmall,
            .link_libc = optimize == .Debug,
            .root_source_file = b.path("demo/demo.zig"),
        });
        exe.root_module.addImport("x11", x11);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step("run", "Run demo");
        run_step.dependOn(&run_cmd.step);
    }
}
