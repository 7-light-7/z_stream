const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const View = @import("view.zig");
const Output = @import("output.zig");
const Seat = @import("seat.zig");

const ZStreamServer = @This();

wl_server: *wl.Server,
backend: *wlr.Backend,
renderer: *wlr.Renderer,
session: ?*wlr.Session,
allocator: *wlr.Allocator,

// Core Wayland protocols
compositor: *wlr.Compositor,
xdg_shell: *wlr.XdgShell,
shm: *wlr.Shm,

// Event listeners
new_xdg_toplevel: wl.Listener(*wlr.XdgToplevel),
new_output: wl.Listener(*wlr.Output),

// State
views: std.ArrayList(*View),
outputs: std.ArrayList(*Output),
seats: std.ArrayList(*Seat),

pub fn init_server(
    server: *ZStreamServer, // function params, just different syntax
    wl_server: *wl.Server,
    backend: *wlr.Backend,
    renderer: *wlr.Renderer,
    session: ?*wlr.Session,
) !void {

    // initialize the core components
    server.* = .{
        .wl_server = wl_server,
        .backend = backend,
        .renderer = renderer,
        .session = session,
        .allocator = try wlr.Allocator.autocreate(backend, renderer),
        .compositor = try wlr.Compositor.create(wl_server, 6, renderer),
        .xdg_shell = try wlr.XdgShell.create(wl_server, 5),
        .shm = try wlr.Shm.createWithRenderer(wl_server, 1, renderer),
        .new_xdg_toplevel = wl.Listener(*wlr.XdgToplevel).init(handleNewXdgToplevel),
        .new_output = wl.Listener(*wlr.Output).init(handleNewOutput),
        .views = std.ArrayList(*View).init(std.heap.page_allocator),
        .outputs = std.ArrayList(*Output).init(std.heap.page_allocator),
        .seats = std.ArrayList(*Seat).init(std.heap.page_allocator),
    };

    // Set up event listeners
    server.xdg_shell.events.new_toplevel.add(&server.new_xdg_toplevel);
    server.backend.events.new_output.add(&server.new_output);

    // Start the backend
    try server.backend.start();
}

pub fn deinit(server: *ZStreamServer) void {
    // Clean up views
    for (server.views.items) |view| {
        view.deinit();
    }
    server.views.deinit();

    // Clean up outputs
    for (server.outputs.items) |output| {
        output.deinit();
    }
    server.outputs.deinit();

    // Clean up seats
    for (server.seats.items) |seat| {
        seat.deinit();
    }
    server.seats.deinit();

    // Remove event listeners
    server.new_xdg_toplevel.link.remove();
    server.new_output.link.remove();

    // Destroy core components
    server.allocator.destroy();
    server.renderer.destroy();
    server.backend.destroy();
}

fn handleNewXdgToplevel(listener: *wl.Listener(*wlr.XdgToplevel), xdg_toplevel: *wlr.XdgToplevel) void {
    const server: *ZStreamServer = @fieldParentPtr(ZStreamServer, listener);
    const view = View.create(server, xdg_toplevel) catch return;
    server.views.append(view) catch return;
}

fn handleNewOutput(listener: *wl.Listener(*wlr.Output), wlr_output: *wlr.Output) void {
    const server: *ZStreamServer = @fieldParentPtr(ZStreamServer, listener);
    const output = Output.create(server, wlr_output) catch return;
    server.outputs.append(output) catch return;
}
