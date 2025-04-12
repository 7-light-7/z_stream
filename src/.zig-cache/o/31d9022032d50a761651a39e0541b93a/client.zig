pub const wl = struct {pub usingnamespace @import("wayland_client_core.zig");
pub usingnamespace @import("wayland_client.zig");};
pub const xdg = struct {pub usingnamespace @import("xdg_shell_client.zig");};
pub const zwp = struct {pub usingnamespace @import("tablet_v2_client.zig");pub usingnamespace @import("pointer_constraints_unstable_v1_client.zig");pub usingnamespace @import("pointer_gestures_unstable_v1_client.zig");};
pub const zxdg = struct {pub usingnamespace @import("xdg_decoration_unstable_v1_client.zig");};
