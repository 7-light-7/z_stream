const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const Server = @import("z_stream_server.zig");

pub var server: Server = undefined;

pub fn main() !void {

    // Create Wayland Server 
    const wl_server = try wl.Server.create();
    const loop = wl_server.getEventLoop(); // TODO: research this 
    

    // Create backend and renderer 
    var session: ?*wlr.Session = undefined;
    const backend = try wlr.backend.autocreate(loop, &session);
    const renderer = try wlr.renderer.autocreate(backend);

    // Create server instance 
    server = try Server.init(wl_server, backend, renderer, session);

    // Run server 
    server.wl_server.run();
    
}

pub const std_options = .{
    .log_level = .debug,
};