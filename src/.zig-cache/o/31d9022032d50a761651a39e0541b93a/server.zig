pub const wl = struct {pub usingnamespace @import("wayland_server_core.zig");
pub usingnamespace @import("wayland_server.zig");};
pub const xdg = struct {pub usingnamespace @import("xdg_shell_server.zig");};
pub const zwp = struct {pub usingnamespace @import("tablet_v2_server.zig");pub usingnamespace @import("pointer_constraints_unstable_v1_server.zig");pub usingnamespace @import("pointer_gestures_unstable_v1_server.zig");};
pub const zxdg = struct {pub usingnamespace @import("xdg_decoration_unstable_v1_server.zig");};
