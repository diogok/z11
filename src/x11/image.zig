const std = @import("std");
const xsetup = @import("setup.zig");
const proto = @import("proto.zig");

const log = std.log.scoped(.x11);

/// Minimal information to be able to convert to X11 image format
pub const ImageInfo = struct {
    visual_type: proto.VisualType,
    format: proto.Format,
};

pub fn getImageInfo(info: xsetup.Setup, root: u32) ImageInfo {
    const target_depth = info.screens[0].root_depth;

    var format_index: usize = 0;
    for (info.formats, 0..) |iformat, index| {
        if (iformat.depth == target_depth) {
            format_index = index;
        }
    }
    const format = info.formats[format_index];

    var screen_index: usize = 0;
    for (info.screens, 0..) |iscreen, index| {
        if (iscreen.root == root) {
            screen_index = index;
        }
    }
    const screen = info.screens[screen_index];

    var depth_index: usize = 0;
    for (screen.allowed_depths, 0..) |idepth, index| {
        if (idepth.depth == target_depth) {
            depth_index = index;
        }
    }
    const allowed_depth = screen.allowed_depths[depth_index];

    const target_visual_id = screen.root_visual;
    var visual_type_index: usize = 0;
    for (allowed_depth.visual_types, 0..) |ivisual_type, index| {
        if (ivisual_type.visual_id == target_visual_id) {
            visual_type_index = index;
        }
    }
    const visual_type = allowed_depth.visual_types[visual_type_index];

    std.debug.print("Format: {any}\n", .{format});
    std.debug.print("VisualType: {any}\n", .{visual_type});

    return .{
        .visual_type = visual_type,
        .format = format,
    };
}

pub fn rgbaToZPixmapAlloc(allocator: std.mem.Allocator, info: ImageInfo, rgba: []const u8) ![]const u8 {
    if (info.visual_type.class != .TrueColor) {
        return error.UnsupportedVisualTypeClass;
    }
    if (info.format.bits_per_pixel != 32) {
        return error.UnsupportedBitsPerPixel;
    }
    if (info.format.bits_per_pixel != info.format.scanline_pad) {
        return error.UnsupportedScanlinePad;
    }

    // Lot of assumptions made here
    const pixels = try allocator.alloc(u8, rgba.len);
    for (0..(rgba.len / 4)) |i| {
        const red = (rgba[i * 4] | info.visual_type.red_mask);
        const green = (rgba[i * 4 + 1] | info.visual_type.green_mask);
        const blue = (rgba[i * 4 + 2] | info.visual_type.blue_mask);

        const pixel: u32 = red | green | blue;

        var buffer: [4]u8 = undefined;
        std.mem.writeInt(u32, &buffer, pixel, .big);

        pixels[i * 4] = buffer[0];
        pixels[i * 4 + 1] = buffer[1];
        pixels[i * 4 + 2] = buffer[2];
        pixels[i * 4 + 3] = buffer[3];
    }

    return pixels;
}
