const std = @import("std");

const Applet = @import("src/main.zig").Applet;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zig_args_mod = b.dependency("zig-args", .{}).module("args");

    const exe = b.addExecutable(.{
        .name = "zus",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });
    exe.root_module.addImport("zig-args", zig_args_mod);
    b.installArtifact(exe);
}
