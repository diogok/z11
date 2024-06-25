const std = @import("std");
const proto = @import("proto.zig");

pub fn send(writer: anytype, request: anytype) !void {
    const req_bytes: []const u8 = &std.mem.toBytes(request);
    try writer.writeAll(req_bytes);
}

pub fn sendWithValues(writer: anytype, request: anytype, values: []const u32) !void {
    try sendWithBytes(writer, request, std.mem.sliceAsBytes(values));
}

pub fn sendWithBytes(writer: anytype, request: anytype, bytes: []const u8) !void {
    var req_bytes = std.mem.toBytes(request);

    // re-calc length to include extra data
    const base_len: u16 = @sizeOf(@TypeOf(request)) / 4;
    const add_len: u16 = @intCast(bytes.len + bytes.len % 4); // need to pad
    const length: u16 = base_len + add_len / 4;
    const len_bytes = std.mem.toBytes(length);
    req_bytes[2] = len_bytes[0];
    req_bytes[3] = len_bytes[1];

    // send request with overriden length
    try writer.writeAll(&req_bytes);

    // write extra bytes
    try writer.writeAll(bytes);

    // pad
    const pad: [3]u8 = .{ 0, 0, 0 };
    try writer.writeAll(pad[0..(bytes.len % 4)]);
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
    switch (message_code) {
        0 => {
            const message = try message_reader.readStruct(proto.ErrorMessage);
            return Message{ .error_message = message };
        },
        1 => {
            const message = try message_reader.readStruct(proto.KeyPress);
            return Message{ .key_press = message };
        },
        12 => {
            const message = try message_reader.readStruct(proto.Expose);
            return Message{ .expose = message };
        },
        13 => {
            const message = try message_reader.readStruct(proto.GraphicsExposure);
            return Message{ .graphics_exposure = message };
        },
        14 => {
            const message = try message_reader.readStruct(proto.NoExposure);
            return Message{ .no_exposure = message };
        },
        else => {
            std.debug.print("Received unkown message: {d}\n", .{message_code});
        },
    }

    return null;
}

const Message = union(enum(u8)) {
    error_message: proto.ErrorMessage,
    key_press: proto.KeyPress,
    expose: proto.Expose,
    graphics_exposure: proto.GraphicsExposure,
    no_exposure: proto.NoExposure,
};
