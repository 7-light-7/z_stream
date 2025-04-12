const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const ZStreamServer = @import("z_stream_server.zig");

const Seat = @This();

server: *ZStreamServer,
wlr_seat: *wlr.Seat,

// Input devices
keyboard: ?*wlr.Keyboard = null,
pointer: ?*wlr.Pointer = null,

// Event listeners
new_input: wl.Listener(*wlr.InputDevice),
keyboard_key: wl.Listener(*wlr.Keyboard.event.Key),
pointer_motion: wl.Listener(*wlr.Pointer.event.Motion),
pointer_motion_absolute: wl.Listener(*wlr.Pointer.event.MotionAbsolute),
pointer_button: wl.Listener(*wlr.Pointer.event.Button),
pointer_axis: wl.Listener(*wlr.Pointer.event.Axis),

pub fn create(server: *ZStreamServer) !*Seat {
    const seat = try std.heap.page_allocator.create(Seat);
    seat.* = .{
        .server = server,
        .wlr_seat = try wlr.Seat.create(server.wl_server, "seat0"),
        .new_input = wl.Listener(*wlr.InputDevice).init(handleNewInput),
        .keyboard_key = wl.Listener(*wlr.Keyboard.event.Key).init(handleKeyboardKey),
        .pointer_motion = wl.Listener(*wlr.Pointer.event.Motion).init(handlePointerMotion),
        .pointer_motion_absolute = wl.Listener(*wlr.Pointer.event.MotionAbsolute).init(handlePointerMotionAbsolute),
        .pointer_button = wl.Listener(*wlr.Pointer.event.Button).init(handlePointerButton),
        .pointer_axis = wl.Listener(*wlr.Pointer.event.Axis).init(handlePointerAxis),
    };

    // Add event listeners
    server.backend.events.new_input.add(&seat.new_input);

    return seat;
}

pub fn deinit(seat: *Seat) void {
    // Remove event listeners
    seat.new_input.link.remove();
    if (seat.keyboard) |_| {
        seat.keyboard_key.link.remove();
    }
    if (seat.pointer) |_| {
        seat.pointer_motion.link.remove();
        seat.pointer_motion_absolute.link.remove();
        seat.pointer_button.link.remove();
        seat.pointer_axis.link.remove();
    }

    seat.wlr_seat.destroy();
    std.heap.page_allocator.destroy(seat);
}

fn handleNewInput(listener: *wl.Listener(*wlr.InputDevice), device: *wlr.InputDevice) void {
    const seat: *Seat = @fieldParentPtr(Seat, listener);

    switch (device.type) {
        .keyboard => {
            const keyboard = device.toKeyboard();
            seat.keyboard = keyboard;
            keyboard.events.key.add(&seat.keyboard_key);
        },
        .pointer => {
            const pointer = device.toPointer();
            seat.pointer = pointer;
            pointer.events.motion.add(&seat.pointer_motion);
            pointer.events.motion_absolute.add(&seat.pointer_motion_absolute);
            pointer.events.button.add(&seat.pointer_button);
            pointer.events.axis.add(&seat.pointer_axis);
        },
        else => {},
    }
}

fn handleKeyboardKey(listener: *wl.Listener(*wlr.Keyboard.event.Key), event: *wlr.Keyboard.event.Key) void {
    const seat: *Seat = @fieldParentPtr(Seat, listener);

    // Handle keyboard input
    if (event.state == .pressed) {
        // Example: Close window on Alt+F4
        if (event.modifiers.alt and event.keycode == 0x3e) { // F4
            if (seat.server.focused_view) |view| {
                view.close();
            }
        }
    }
}

fn handlePointerMotion(listener: *wl.Listener(*wlr.Pointer.event.Motion), event: *wlr.Pointer.event.Motion) void {
    const seat: *Seat = @fieldParentPtr(Seat, listener);

    // Update pointer position
    seat.wlr_seat.pointerNotifyMotion(event.time_msec, event.delta_x, event.delta_y);
}

fn handlePointerMotionAbsolute(listener: *wl.Listener(*wlr.Pointer.event.MotionAbsolute), event: *wlr.Pointer.event.MotionAbsolute) void {
    const seat: *Seat = @fieldParentPtr(Seat, listener);

    // Update absolute pointer position
    seat.wlr_seat.pointerNotifyMotionAbsolute(event.time_msec, event.x, event.y);
}

fn handlePointerButton(listener: *wl.Listener(*wlr.Pointer.event.Button), event: *wlr.Pointer.event.Button) void {
    const seat: *Seat = @fieldParentPtr(Seat, listener);

    // Handle pointer button events
    seat.wlr_seat.pointerNotifyButton(event.time_msec, event.button, event.state);
}

fn handlePointerAxis(listener: *wl.Listener(*wlr.Pointer.event.Axis), event: *wlr.Pointer.event.Axis) void {
    const seat: *Seat = @fieldParentPtr(Seat, listener);

    // Handle pointer axis events (scroll wheel)
    seat.wlr_seat.pointerNotifyAxis(event.time_msec, event.orientation, event.delta, event.delta_discrete, event.source);
}
