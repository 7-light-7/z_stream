const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const ZStreamServer = @import("z_stream_server.zig");

const View = @This();

server: *ZStreamServer,
xdg_toplevel: *wlr.XdgToplevel,
surface: *wlr.Surface,

// Event listeners
map: wl.Listener(void),
unmap: wl.Listener(void),
destroy: wl.Listener(void),
commit: wl.Listener(*wlr.Surface),
request_move: wl.Listener(*wlr.XdgToplevel.event.Move),
request_resize: wl.Listener(*wlr.XdgToplevel.event.Resize),

// State
x: i32 = 0,
y: i32 = 0,
width: i32 = 0,
height: i32 = 0,
mapped: bool = false,

pub fn create(server: *ZStreamServer, xdg_toplevel: *wlr.XdgToplevel) !*View {
    const view = try std.heap.page_allocator.create(View);
    view.* = .{
        .server = server,
        .xdg_toplevel = xdg_toplevel,
        .surface = xdg_toplevel.base.surface,
        .map = wl.Listener(void).init(handleMap),
        .unmap = wl.Listener(void).init(handleUnmap),
        .destroy = wl.Listener(void).init(handleDestroy),
        .commit = wl.Listener(*wlr.Surface).init(handleCommit),
        .request_move = wl.Listener(*wlr.XdgToplevel.event.Move).init(handleRequestMove),
        .request_resize = wl.Listener(*wlr.XdgToplevel.event.Resize).init(handleRequestResize),
    };

    // Add event listeners
    xdg_toplevel.base.events.map.add(&view.map);
    xdg_toplevel.base.events.unmap.add(&view.unmap);
    xdg_toplevel.base.events.destroy.add(&view.destroy);
    xdg_toplevel.events.commit.add(&view.commit);
    xdg_toplevel.events.request_move.add(&view.request_move);
    xdg_toplevel.events.request_resize.add(&view.request_resize);

    return view;
}

pub fn deinit(view: *View) void {
    // Remove event listeners
    view.map.link.remove();
    view.unmap.link.remove();
    view.destroy.link.remove();
    view.commit.link.remove();
    view.request_move.link.remove();
    view.request_resize.link.remove();

    std.heap.page_allocator.destroy(view);
}

fn handleMap(listener: *wl.Listener(void)) void {
    const view: *View = @fieldParentPtr(View, listener);

    // Set initial window position and size
    view.width = view.surface.current.width;
    view.height = view.surface.current.height;
    view.mapped = true;

    // Add to server's view list
    view.server.views.append(view) catch return;

    // Focus the new window
    view.server.focused_view = view;
}

fn handleUnmap(listener: *wl.Listener(void)) void {
    const view: *View = @fieldParentPtr(View, listener);

    view.mapped = false;

    // Remove from server's view list
    if (view.server.views.items.len > 0) {
        const index = std.mem.indexOfScalar(*View, view.server.views.items, view) orelse return;
        _ = view.server.views.swapRemove(index);
    }

    // Focus another window if this was the focused one
    if (view.server.focused_view == view) {
        view.server.focused_view = if (view.server.views.items.len > 0)
            view.server.views.items[view.server.views.items.len - 1]
        else
            null;
    }
}

fn handleDestroy(listener: *wl.Listener(void)) void {
    const view: *View = @fieldParentPtr(View, listener);
    view.deinit();
}

fn handleCommit(listener: *wl.Listener(*wlr.Surface), surface: *wlr.Surface) void {
    const view: *View = @fieldParentPtr(View, listener);

    // Update window size if it changed
    if (surface.current.width != view.width or surface.current.height != view.height) {
        view.width = surface.current.width;
        view.height = surface.current.height;
    }
}

fn handleRequestMove(listener: *wl.Listener(*wlr.XdgToplevel.event.Move), event: *wlr.XdgToplevel.event.Move) void {
    const view: *View = @fieldParentPtr(View, listener);

    // Start interactive move
    view.server.grabbed_view = view;
    view.server.grab_x = view.x - event.sx;
    view.server.grab_y = view.y - event.sy;
}

fn handleRequestResize(listener: *wl.Listener(*wlr.XdgToplevel.event.Resize), event: *wlr.XdgToplevel.event.Resize) void {
    const view: *View = @fieldParentPtr(View, listener);

    // Start interactive resize
    view.server.grabbed_view = view;
    view.server.grab_x = view.x;
    view.server.grab_y = view.y;
    view.server.grab_width = view.width;
    view.server.grab_height = view.height;
    view.server.resize_edges = event.edges;
}
