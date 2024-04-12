const std = @import("std");

pub fn build(b: *std.Build) void {
    const zreload_module = b.addModule("zreload", .{
        .root_source_file = .{ .path = "src/lib.zig" },
        .imports = &.{},
    });

    // Examples
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "shade",
        .root_source_file = .{ .path = "src/example.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zreload", zreload_module);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
