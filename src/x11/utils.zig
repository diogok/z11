const std = @import("std");
const proto = @import("proto.zig");
const io = @import("io.zig");

const testing = std.testing;

const log = std.log.scoped(.x11);

pub fn mask(values: anytype) u32 {
    var value_mask: u32 = 0;
    for (values) |value| {
        value_mask |= @intFromEnum(value);
    }
    return value_mask;
}

test "mask" {}

pub fn maskFromValues(comptime MaskType: type, values: anytype) u32 {
    var value_mask: u32 = 0;
    inline for (@typeInfo(@TypeOf(values)).Struct.fields) |field| {
        const value = @field(values, field.name);
        if (value) |_| {
            value_mask |= @intFromEnum(@field(MaskType, field.name));
        }
    }
    return value_mask;
}

test "mask from values" {
    const result = maskFromValues(proto.WindowMask, proto.WindowValue{
        .Colormap = 2,
        .BackgroundPixel = 1,
        .EventMask = 0b1,
    });
    const expected: u32 = @intFromEnum(proto.WindowMask.BackgroundPixel) | @intFromEnum(proto.WindowMask.EventMask) | @intFromEnum(proto.WindowMask.Colormap);
    try testing.expectEqual(expected, result);
}

fn bufferFor(MaskType: type) [@typeInfo(MaskType).Struct.fields.len * 4]u8 {
    const buffer: [@typeInfo(MaskType).Struct.fields.len * 4]u8 = undefined;
    return buffer;
}

fn bytesFromValues(buffer: []u8, values: anytype) []const u8 {
    var bytes_len: usize = 0;
    inline for (@typeInfo(@TypeOf(values)).Struct.fields) |field| {
        const value = @field(values, field.name);
        if (value) |v| {
            std.mem.copyForwards(u8, buffer[bytes_len..], std.mem.asBytes(&v));
            bytes_len += @sizeOf(@TypeOf(v));
        }
    }
    return buffer[0..bytes_len];
}

test "bytesFromValues" {
    const values = proto.WindowValue{
        .Colormap = 2,
        .BackgroundPixel = 3,
        .EventMask = 0b1,
    };
    var buffer = bufferFor(proto.WindowValue);
    const bytes = bytesFromValues(&buffer, values);
    const expected = [_]u8{
        0b11, 0b0, 0b0, 0b0, // BackgroundPixel
        0b1, 0b0, 0b0, 0b0, // EventMask
        0b10, 0b0, 0b0, 0b0, // Colormap
    };
    try testing.expectEqualSlices(u8, &expected, bytes);
}

pub fn sendWithValues(writer: anytype, request: anytype, values: anytype) !void {
    var buffer = bufferFor(@TypeOf(values));
    const bytes = bytesFromValues(&buffer, values);
    try io.sendWithBytes(writer, request, bytes);
}

pub fn internAtom(conn: anytype, name: []const u8) !u32 {
    const request = proto.InternAtom{ .length_of_name = @truncate(name.len) };
    std.debug.print("intern this: {any} {s}\n", .{ request, name });
    try io.sendWithBytes(conn, request, name);

    const reply = try io.receiveReply(conn, proto.InternAtomReply);
    if (reply) |r| {
        std.debug.print("ATOM {s} {any}\n", .{ name, r });
        return r.atom;
    }

    return error.FailedToInternAtom;
}

pub fn getProperty(conn: anytype, window_id: u32, atom: u32) !proto.GetPropertyReply {
    const request = proto.GetProperty{ .window_id = window_id, .property = atom };
    try io.send(conn, request);

    const reply = try io.receiveReply(conn, proto.GetPropertyReply);
    if (reply) |r| {
        return r;
    }

    return error.FailedToGetProperty;
}

pub fn clientMessageData(clientMesage: proto.ClientMessage) ClientMessageData {
    switch (clientMesage.format) {
        8 => {
            return ClientMessageData{ .u8 = clientMesage.data };
        },
        16 => {
            return ClientMessageData{ .u16 = std.mem.bytesToValue([10]u16, &clientMesage.data) };
        },
        32 => {
            return ClientMessageData{ .u32 = std.mem.bytesToValue([5]u32, &clientMesage.data) };
        },
        else => {
            return ClientMessageData{ .u8 = clientMesage.data };
        },
    }
}

pub const ClientMessageData = union(enum) {
    u8: [20]u8,
    u16: [10]u16,
    u32: [5]u32,
};
