const std = @import("std");
const proto = @import("proto.zig");

const testing = std.testing;

pub fn send(writer: anytype, request: anytype) !void {
    const req_bytes: []const u8 = &std.mem.toBytes(request);
    try writer.writeAll(req_bytes);
}

pub fn sendWithBytes(writer: anytype, request: anytype, bytes: []const u8) !void {
    var req_bytes = std.mem.toBytes(request);

    // re-calc length to include extra data
    const length = get_padded_len(request, bytes);
    const len_bytes = std.mem.toBytes(length);
    req_bytes[2] = len_bytes[0];
    req_bytes[3] = len_bytes[1];

    // send request with overriden length
    try writer.writeAll(&req_bytes);

    // write extra bytes
    try writer.writeAll(bytes);

    // pad
    const pad_len = get_pad_len(bytes);
    const padding: [3]u8 = .{ 0, 0, 0 };
    const pad = padding[0..pad_len];
    try writer.writeAll(pad);
}

fn get_padded_len(request: anytype, bytes: []const u8) u16 {
    const req_len: u16 = @sizeOf(@TypeOf(request)) / 4;
    const bytes_len: u16 = @intCast(bytes.len);
    const pad_len: u16 = get_pad_len(bytes);
    const extra_len: u16 = (bytes_len + pad_len) / 4;
    const length: u16 = req_len + extra_len;
    return length;
}

test "Length calc" {
    const change_prop = proto.ChangeProperty{ .window_id = 0, .property = 0, .property_type = 0 };
    const len0 = get_padded_len(change_prop, "");

    try testing.expectEqual(6, len0);

    const len1 = get_padded_len(change_prop, "hello");
    try testing.expectEqual(8, len1);
}

fn get_pad_len(bytes: []const u8) u16 {
    const missing = bytes.len % 4;
    if (missing == 0) {
        return 0;
    }
    const pad: u16 = @intCast(4 - missing);
    return pad;
}

test "padding length" {
    const len0 = get_pad_len("");
    try testing.expectEqual(0, len0);

    const len1 = get_pad_len("1234");
    try testing.expectEqual(0, len1);

    const len2 = get_pad_len("12345");
    try testing.expectEqual(3, len2);

    const len3 = get_pad_len("12345678");
    try testing.expectEqual(0, len3);
}

pub fn receive(reader: anytype) !?Message {
    var message_buffer: [32]u8 = undefined;
    _ = reader.read(&message_buffer) catch |err| {
        switch (err) {
            error.WouldBlock => return null,
            else => return err,
        }
    };

    var message_stream = std.io.fixedBufferStream(&message_buffer);
    var message_reader = message_stream.reader();

    const message_code = message_buffer[0];

    const message_tag = std.meta.Tag(Message);
    const message_values = comptime std.meta.fields(message_tag);
    inline for (message_values) |tag| {
        if (message_code == tag.value) {
            const message = try message_reader.readStruct(@field(proto, tag.name));
            return @unionInit(Message, tag.name, message);
        }
    }

    return null;
}

const Message = union(enum(u8)) {
    ErrorMessage: proto.ErrorMessage,
    Placeholder: proto.Placeholder,
    KeyPress: proto.KeyPress,
    KeyRelease: proto.KeyRelease,
    ButtonPress: proto.ButtonPress,
    ButtonRelease: proto.ButtonRelease,
    MotionNotify: proto.MotionNotify,
    EnterNotify: proto.EnterNotify,
    LeaveNotify: proto.LeaveNotify,
    FocusIn: proto.FocusIn,
    FocusOut: proto.FocusOut,
    KeymapNotify: proto.KeymapNotify,
    Expose: proto.Expose,
    GraphicsExposure: proto.GraphicsExposure,
    NoExposure: proto.NoExposure,
    VisibilityNotify: proto.VisibilityNotify,
    CreateNotify: proto.CreateNotify,
    DestroyNotify: proto.DestroyNotify,
    UnmapNotify: proto.UnmapNotify,
    MapNotify: proto.MapNotify,
    MapRequest: proto.MapRequest,
    ReparentNotify: proto.ReparentNotify,
    ConfigureNotify: proto.ConfigureNotify,
    ConfigureRequest: proto.ConfigureRequest,
    GravityNotify: proto.GravityNotify,
    ResizeRequest: proto.ResizeRequest,
    CirculateNotify: proto.CirculateNotify,
    CirculateRequest: proto.CirculateRequest,
    PropertyNotify: proto.PropertyNotify,
    SelectionClear: proto.SelectionClear,
    SelectionRequest: proto.SelectionRequest,
    SelectionNotify: proto.SelectionNotify,
    ColormapNotify: proto.ColormapNotify,
    ClientMessage: proto.ClientMessage,
    MappingNotify: proto.MappingNotify,
};
