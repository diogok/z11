const std = @import("std");

fn open_xauth_file() !std.fs.File {
    if (std.posix.getenv("XAUTHORITY")) |file| {
        return std.fs.openFileAbsolute(file, .{});
    } else if (std.posix.getenv("HOME")) |home| {
        var dir = try std.fs.openDirAbsolute(home, .{});
        defer dir.close();
        return dir.openFile(".Xauthority", .{});
    } else {
        return error.NoAuthorityFileFound;
    }
}

fn read_xauth_file(allocator: std.mem.Allocator, xauth_file: std.fs.File) !XAuth {
    var xauth_reader = xauth_file.reader();

    // Skip unsupported fields
    try xauth_reader.skipBytes(2, .{}); // skip family
    const address_len = try xauth_reader.readInt(u16, .big); // size of address
    try xauth_reader.skipBytes(address_len, .{}); // skip address
    const number_len = try xauth_reader.readInt(u16, .big); // size of number
    try xauth_reader.skipBytes(number_len, .{}); // skip number

    // Read auth name
    const xauth_name_len = try xauth_reader.readInt(u16, .big); // size of xauth name
    const xauth_name = try allocator.alloc(u8, xauth_name_len);
    errdefer allocator.free(xauth_name);
    _ = try xauth_reader.read(xauth_name); // read name

    // Read auth data
    const xauth_data_len = try xauth_reader.readInt(u16, .big); // size of xauth data
    const xauth_data = try allocator.alloc(u8, xauth_data_len);
    errdefer allocator.free(xauth_data);
    _ = try xauth_reader.read(xauth_data); // read data

    if (!std.mem.eql(u8, xauth_name, "MIT-MAGIC-COOKIE-1")) {
        return error.UnsupportedAuth;
    }

    return .{
        .name = xauth_name,
        .data = xauth_data,
        .allocator = allocator,
    };
}

pub const XAuth = struct {
    name: []const u8,
    data: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: @This()) void {
        self.allocator.free(self.name);
        self.allocator.free(self.data);
    }
};

pub fn get_auth(allocator: std.mem.Allocator) !XAuth {
    const xauth_file = try open_xauth_file();
    defer xauth_file.close();
    const xauth = try read_xauth_file(allocator, xauth_file);
    return xauth;
}
