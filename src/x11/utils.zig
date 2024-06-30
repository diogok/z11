const std = @import("std");
const proto = @import("proto.zig");
const io = @import("io.zig");

const testing = std.testing;

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
