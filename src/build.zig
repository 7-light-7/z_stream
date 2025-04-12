const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const strip = b.option(bool, "strip", "Omit debug information") orelse false;
    const pie = b.option(bool, "pie", "Build a Position Independent Executable") orelse false;
    const llvm = !(b.option(bool, "no-llvm", "(experimental) Use non-LLVM x86 Zig backend") orelse false);

    const omit_frame_pointer = switch (optimize) {
        .Debug, .ReleaseSafe => false,
        .ReleaseFast, .ReleaseSmall => true,
    };

    // Get the Wayland scanner
    const Scanner = @import("zig-wayland").Scanner;
    const scanner = Scanner.create(b, .{});

    // Add required Wayland protocols
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("stable/tablet/tablet-v2.xml");
    scanner.addSystemProtocol("staging/cursor-shape/cursor-shape-v1.xml");
    scanner.addSystemProtocol("staging/ext-session-lock/ext-session-lock-v1.xml");
    scanner.addSystemProtocol("staging/tearing-control/tearing-control-v1.xml");
    scanner.addSystemProtocol("unstable/pointer-constraints/pointer-constraints-unstable-v1.xml");
    scanner.addSystemProtocol("unstable/pointer-gestures/pointer-gestures-unstable-v1.xml");
    scanner.addSystemProtocol("unstable/xdg-decoration/xdg-decoration-unstable-v1.xml");

    // Generate Wayland protocol bindings
    scanner.generate("wl_compositor", 4);
    scanner.generate("wl_subcompositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_seat", 7);
    scanner.generate("wl_data_device_manager", 3);
    scanner.generate("xdg_wm_base", 2);
    scanner.generate("zwp_pointer_gestures_v1", 3);
    scanner.generate("zwp_pointer_constraints_v1", 1);
    scanner.generate("zwp_tablet_manager_v2", 1);
    scanner.generate("zxdg_decoration_manager_v1", 1);
    scanner.generate("ext_session_lock_manager_v1", 1);
    scanner.generate("wp_cursor_shape_manager_v1", 1);
    scanner.generate("wp_tearing_control_manager_v1", 1);

    // Create the Wayland module
    const wayland = b.createModule(.{ .root_source_file = scanner.result });

    // Get other dependencies
    const xkbcommon = b.dependency("zig-xkbcommon", .{}).module("xkbcommon");
    const pixman = b.dependency("zig-pixman", .{}).module("pixman");

    // Get wlroots as a module
    const wlroots = b.dependency("zig-wlroots", .{}).module("wlroots");
    wlroots.addImport("wayland", wayland);
    wlroots.addImport("xkbcommon", xkbcommon);
    wlroots.addImport("pixman", pixman);
    wlroots.resolved_target = target;
    wlroots.linkSystemLibrary("wlroots-0.18", .{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "z_stream_server",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
        .use_llvm = llvm,
        .use_lld = llvm,
    });

    // Link required system libraries
    exe.linkLibC();
    exe.linkSystemLibrary("libevdev");
    exe.linkSystemLibrary("libinput");
    exe.linkSystemLibrary("wayland-server");
    exe.linkSystemLibrary("wlroots-0.18");
    exe.linkSystemLibrary("xkbcommon");
    exe.linkSystemLibrary("pixman-1");

    // Add dependencies as module imports
    exe.root_module.addImport("wayland", wayland);
    exe.root_module.addImport("xkbcommon", xkbcommon);
    exe.root_module.addImport("pixman", pixman);
    exe.root_module.addImport("wlroots", wlroots);

    exe.pie = pie;
    exe.root_module.omit_frame_pointer = omit_frame_pointer;

    // Install the artifact
    b.installArtifact(exe);

    // Create a run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);
}
