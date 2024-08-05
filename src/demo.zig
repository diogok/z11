const std = @import("std");
const x11 = @import("x11");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() != .leak);
    const allocator = gpa.allocator();

    const conn = try x11.connect(.{});
    defer conn.close();

    const info = try x11.setup(allocator, conn);
    defer info.deinit();

    var xID = x11.XID.init(info.resource_id_base, info.resource_id_mask);

    try x11.sendWithBytes(conn, x11.InternAtom{ .length_of_name = "WM_PROTOCOLS".len }, "WM_PROTOCOLS");
    const wmProtocolsAtom = try x11.receiveReply(conn, x11.InternAtomReply);
    std.debug.print("atom WM_PROTOCOLS {any}\n", .{wmProtocolsAtom});

    const string_atom = try x11.internAtom(conn, "STRING");
    //_ = string_atom;
    //const wm_name_atom = try x11.internAtom(conn, "WM_NAME");
    //_ = wm_name_atom;
    //const wm_delete_window_atom = try x11.internAtom(conn, "WM_DELETE_WINDOW");
    //std.debug.print("atom delete {d}\n", .{wm_delete_window_atom});

    const window_id = try xID.genID();
    const event_masks = [_]x11.EventMask{ .Exposure, .StructureNotify, .SubstructureNotify, .PropertyChange };
    const window_values = x11.WindowValue{
        .BackgroundPixel = info.screens[0].black_pixel,
        .EventMask = x11.mask(&event_masks),
        .Colormap = info.screens[0].colormap,
    };
    const create_window = x11.CreateWindow{
        .window_id = window_id,

        .parent_id = info.screens[0].root,
        .visual_id = info.screens[0].root_visual,
        .depth = info.screens[0].root_depth,

        .x = 10,
        .y = 10,
        .width = 480,
        .height = 240,
        .border_width = 0,
        .window_class = .InputOutput,

        .value_mask = x11.maskFromValues(x11.WindowMask, window_values),
    };
    try x11.sendWithValues(conn, create_window, window_values);

    const map_req = x11.MapWindow{ .window_id = window_id };
    try x11.send(conn, map_req);

    const set_name_req = x11.ChangeProperty{
        .window_id = window_id,
        .property = 39, //wm_name_atom,
        .property_type = string_atom,
        .length_of_data = 5,
    };
    //_ = set_name_req;
    try x11.sendWithBytes(conn, set_name_req, "hello");
    //const wm_name_prop = try x11.getProperty(conn, window_id, wm_name_aom);
    //std.debug.print("Prop: {any}\n", .{wm_name_prop});

    const graphic_context_id = try xID.genID();
    const graphic_context_values = x11.GraphicContextValue{
        .Background = info.screens[0].black_pixel,
        .Foreground = info.screens[0].white_pixel,
    };
    const create_gc = x11.CreateGraphicContext{
        .graphic_context_id = graphic_context_id,
        .drawable_id = window_id,
        .value_mask = x11.maskFromValues(x11.GraphicContextMask, graphic_context_values),
    };
    try x11.sendWithValues(conn, create_gc, graphic_context_values);

    const pixmap_id = try xID.genID();
    const pixmap_req = x11.CreatePixmap{
        .pixmap_id = pixmap_id,
        .drawable_id = window_id,
        .width = 5,
        .height = 5,
        .depth = create_window.depth,
    };
    try x11.send(conn, pixmap_req);

    var yellow_block: [5 * 5 * 4]u8 = undefined;
    var byte_index: usize = 0;
    while (byte_index < yellow_block.len) : (byte_index += 4) {
        yellow_block[byte_index] = 255; // red
        yellow_block[byte_index + 1] = 150; // green
        yellow_block[byte_index + 2] = 0; // blue
        yellow_block[byte_index + 3] = 0; // padding
    }

    const imageInfo = x11.getImageInfo(info, create_window.parent_id);
    const yellow_block_zpixmap = try x11.rgbaToZPixmapAlloc(allocator, imageInfo, &yellow_block);
    defer allocator.free(yellow_block_zpixmap);

    const put_image_req = x11.PutImage{
        .drawable_id = pixmap_id,
        .graphic_context_id = graphic_context_id,
        .width = 5,
        .height = 5,
        .x = 0,
        .y = 0,
        .depth = pixmap_req.depth,
    };
    try x11.sendWithBytes(conn, put_image_req, yellow_block_zpixmap);

    var open = true;
    while (open) {
        while (try x11.receive(conn)) |message| {
            std.debug.print("Received: {any}\n", .{message});
            switch (message) {
                .Expose => {
                    const clear_area = x11.ClearArea{
                        .window_id = window_id,
                    };
                    try x11.send(conn, clear_area);

                    const copy_area_req = x11.CopyArea{
                        .src_drawable_id = pixmap_id,
                        .dst_drawable_id = window_id,
                        .graphic_context_id = graphic_context_id,
                        .width = pixmap_req.width,
                        .height = pixmap_req.height,
                        .dst_x = 100,
                        .dst_y = 200,
                    };
                    try x11.send(conn, copy_area_req);
                },
                .DestroyNotify => {
                    open = false;
                },
                else => {},
            }
        }
    }

    try x11.send(conn, x11.FreeGraphicContext{ .graphic_context_id = graphic_context_id });
    try x11.send(conn, x11.FreePixmap{ .pixmap_id = pixmap_id });
    try x11.send(conn, x11.UnmapWindow{ .window_id = window_id });
    try x11.send(conn, x11.DestroyWindow{ .window_id = window_id });
}
