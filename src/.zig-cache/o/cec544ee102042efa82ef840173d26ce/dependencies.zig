pub const packages = struct {
    pub const @"122060ddef836b7872cb2088764a8bd2fb2e9254327673e8176b7f7a621ec897484f" = struct {
        pub const build_root = "/home/_light_/.cache/zig/p/122060ddef836b7872cb2088764a8bd2fb2e9254327673e8176b7f7a621ec897484f";
        pub const build_zig = @import("122060ddef836b7872cb2088764a8bd2fb2e9254327673e8176b7f7a621ec897484f");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "zig-pixman", "12209db20ce873af176138b76632931def33a10539387cba745db72933c43d274d56" },
            .{ "zig-wayland", "1220687c8c47a48ba285d26a05600f8700d37fc637e223ced3aa8324f3650bf52242" },
            .{ "zig-xkbcommon", "1220c90b2228d65fd8427a837d31b0add83e9fade1dcfa539bb56fd06f1f8461605f" },
        };
    };
    pub const @"1220687c8c47a48ba285d26a05600f8700d37fc637e223ced3aa8324f3650bf52242" = struct {
        pub const available = false;
    };
    pub const @"12209db20ce873af176138b76632931def33a10539387cba745db72933c43d274d56" = struct {
        pub const available = false;
    };
    pub const @"1220c90b2228d65fd8427a837d31b0add83e9fade1dcfa539bb56fd06f1f8461605f" = struct {
        pub const available = false;
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "wlroots", "122060ddef836b7872cb2088764a8bd2fb2e9254327673e8176b7f7a621ec897484f" },
};
