const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("base64", .{
        .root_source_file = b.path("src/base64.zig"),
        .target = target,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "base64", .module = mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "base64",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const check_exe = b.addExecutable(.{
        .name = "base64",
        .root_module = exe_mod,
    });

    const check_step = b.step("check", "Check if base64 compiles");
    check_step.dependOn(&check_exe.step);
}
