const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const ZStreamServer = @import("z_stream_server.zig");

const Output = @This();

server: *ZStreamServer,
wlr_output: *wlr.Output,

// Event listeners
frame: wl.Listener(*wlr.Output),
destroy: wl.Listener(void),

pub fn create(server: *ZStreamServer, wlr_output: *wlr.Output) !*Output {
    const output = try std.heap.page_allocator.create(Output);
    output.* = .{
        .server = server,
        .wlr_output = wlr_output,
        .frame = wl.Listener(*wlr.Output).init(handleFrame),
        .destroy = wl.Listener(void).init(handleDestroy),
    };

    // Add event listeners
    wlr_output.events.frame.add(&output.frame);
    wlr_output.events.destroy.add(&output.destroy);

    // Initialize output
    try wlr_output.initRender(server.allocator, server.renderer);

    // Set up output mode
    if (wlr_output.preferredMode()) |mode| {
        wlr_output.setMode(mode);
        wlr_output.enable(true);
        wlr_output.commit();
    }

    return output;
}

pub fn deinit(output: *Output) void {
    // Remove event listeners
    output.frame.link.remove();
    output.destroy.link.remove();

    std.heap.page_allocator.destroy(output);
}

fn handleFrame(listener: *wl.Listener(*wlr.Output), wlr_output: *wlr.Output) void {
    const output: *Output = @fieldParentPtr(Output, listener);
    
    // Begin rendering
    const renderer = output.server.renderer;
    
    // Render the scene
    renderer.begin(wlr_output.width, wlr_output.height);
    renderer.clear(&.{ 0.3, 0.3, 0.3, 1.0 });
    
    // Render all views
    for (output.server.views.items) |view| {
        if (view.surface.mapped) {
            renderer.renderSurface(view.surface, view.x, view.y);
        }
    }
    
    renderer.end();
    wlr_output.swapBuffers();
}

fn handleDestroy(listener: *wl.Listener(void)) void {
    const output: *Output = @fieldParentPtr(Output, listener);
    output.deinit();
}