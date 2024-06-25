pub const Point = extern struct {
    x: i16 = 0,
    y: i16 = 0,
};

pub const Rectangle = extern struct {
    x: i16 = 0,
    y: i16 = 0,
    width: u16 = 0,
    height: u16 = 0,
};

pub const Arc = extern struct {
    x: i16 = 0,
    y: i16 = 0,
    width: u16 = 0,
    height: u16 = 0,
    angle1: i16 = 0,
    angle2: i16 = 0,
};

pub const Format = extern struct {
    depth: u8,
    bits_per_pixel: u8,
    scanline_pad: u8,
    pad: [5]u8,
};

pub const VisualClass = enum(u8) {
    StaticGray = 0,
    GrayScale = 1,
    StaticColor = 2,
    PseudoColor = 3,
    TrueColor = 4,
    DirectColor = 5,
};

pub const VisualType = extern struct {
    visual_id: u32,
    class: VisualClass,
    bits_per_rgb_value: u8,
    colormap_entries: u16,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    pad: [4]u8,
};

pub const Depth = extern struct {
    depth: u8,
    pad0: [1]u8,
    visual_type_len: u16,
    pad1: [4]u8,
};

pub const EventMask = enum(u32) {
    //NoEvent = 0b0,
    KeyPress = 0b1,
    KeyRelease = 0b10,
    ButtonPress = 0b100,
    ButtonRelease = 0b1000,
    EnterWindow = 0b10000,
    LeaveWindow = 0b100000,
    PointerMotion = 0b1000000,
    PointerMotionHint = 0b10000000,
    Button1Motion = 0b100000000,
    Button2Motion = 0b1000000000,
    Button3Motion = 0b10000000000,
    Button4Motion = 0b100000000000,
    Button5Motion = 0b1000000000000,
    ButtonMotion = 0b10000000000000,
    KeymapState = 0b100000000000000,
    Exposure = 0b1000000000000000,
    VisibilityChange = 0b10000000000000000,
    StructureNotify = 0b100000000000000000,
    ResizeRedirect = 0b1000000000000000000,
    SubstructureNotify = 0b10000000000000000000,
    SubstructureRedirect = 0b100000000000000000000,
    FocusChange = 0b1000000000000000000000,
    PropertyChange = 0b10000000000000000000000,
    ColormapChange = 0b100000000000000000000000,
    OwnerGrabButton = 0b1000000000000000000000000,
};

pub const EventMaskAll = blk: {
    var all: u32 = 0;
    const masks = @typeInfo(EventMask).Enum.fields;
    for (masks) |mask| {
        all |= mask.value;
    }
    break :blk all;
};

pub const BackingStore = enum(u8) {
    NotUseful = 0,
    WhenMapped = 1,
    Always = 2,
};

pub const Screen = extern struct {
    root: u32,
    colormap: u32,
    white_pixel: u32,
    black_pixel: u32,

    current_input_masks: u32,
    width_in_pixels: u16,
    height_in_pixels: u16,
    width_in_millimeters: u16,
    height_in_millimeters: u16,
    min_installed_maps: u16,
    max_installed_maps: u16,

    root_visual: u32,

    backing_stores: BackingStore,
    save_unders: u8,

    root_depth: u8,
    allowed_depths_len: u8,
};

pub const SetupRequest = extern struct {
    byte_order: u8 = switch (@import("builtin").cpu.arch.endian()) {
        .big => 'B',
        .little => 'l',
    },
    pad0: u8 = 0,
    protocol_major_version: u16 = 11,
    procotol_minor_version: u16 = 0,
    auth_name_len: u16,
    auth_data_len: u16,
    pad1: [2]u8 = [2]u8{ 0, 0 },
    // must send auth data and padding
};

pub const ImageByteOrder = enum(u8) {
    LSBFirst = 0,
    MSBFirst = 1,
};

pub const BitmapFormatBitOrder = enum(u8) {
    LeastSignificant = 0,
    MostSignificant = 1,
};

pub const SetupStatus = extern struct {
    status: u8,
    pad: u8,
    major_version: u16,
    minor_version: u16,
    reply_len: u16,
};

pub const SetupContent = extern struct {
    release_number: u32,
    resource_id_base: u32,
    resource_id_mask: u32,
    motion_buffer_size: u32,
    vendor_len: u16,
    maximum_request_length: u16,
    roots_len: u8,
    pixmap_formats_len: u8,
    image_byte_order: ImageByteOrder,
    bitmap_format_bit_order: BitmapFormatBitOrder,
    bitmap_format_scanline_unit: u8,
    bitmap_format_scanline_pad: u8,
    min_keycode: u8,
    max_keycode: u8,
    pad: [4]u8,
};

pub const CreateWindow = extern struct {
    opcode: u8 = 1,
    depth: u8,
    length: u16 = (@sizeOf(@This()) / 4),
    window_id: u32,
    parent_id: u32,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    window_class: WindowClass,
    visual_id: u32,
    value_mask: u32 = 0,
};

pub const WindowClass = enum(u16) {
    Parent = 0,
    InputOutput = 1,
    InputOnly = 2,
};

pub const WindowMask = enum(u32) {
    back_pixmap = 1,
    back_pixel = 2,
    border_pixmap = 4,
    border_pixel = 8,
    bit_gravity = 16,
    win_gravity = 32,
    backing_store = 64,
    backing_planes = 128,
    backing_pixel = 256,
    override_redirect = 512,
    save_under = 1024,
    event_mask = 2048,
    dont_propagate = 4096,
    colormap = 8192,
    cursor = 16348,
};

pub const ChangeWindowAttributes = extern struct {
    opcode: u8 = 5,
};

pub const DestroyWindow = extern struct {
    opcode: u8 = 4,
    pad: u8 = 0,
    length: u16 = @sizeOf(@This()) / 4,
    window_id: u32,
};

pub const MapWindow = extern struct {
    opcode: u8 = 8,
    pad: u8 = 0,
    length: u16 = @sizeOf(@This()) / 4,
    window_id: u32,
};

pub const UnmapWindow = extern struct {
    opcode: u8 = 10,
    pad: u8 = 0,
    length: u16 = @sizeOf(@This()) / 4,
    window_id: u32,
};

pub const CreatePixmap = extern struct {
    opcode: u8 = 53,
    depth: u8,
    length: u16 = (@sizeOf(@This()) / 4),
    pixmap_id: u32,
    drawable_id: u32,
    width: u16,
    height: u16,
};

pub const FreePixmap = extern struct {
    opcode: u8 = 54,
    pad0: u8 = 0,
    length: u16 = @sizeOf(@This()) / 4,
    pixmap_id: u32,
};

pub const CreateGraphicContext = extern struct {
    opcode: u8 = 55,
    pad: u8 = 0,
    length: u16 = (@sizeOf(@This()) / 4),
    graphic_context_id: u32,
    drawable_id: u32,
    value_mask: u32 = 0,
};

pub const GraphicContextMask = enum(u32) {
    to_do,
};

pub const FreeGraphicContext = extern struct {
    opcode: u8 = 60,
    pad0: u8 = 0,
    length: u16 = @sizeOf(@This()) / 4,
    graphic_context_id: u32,
};

pub const PutImage = extern struct {
    opcode: u8 = 72,
    format: ImageFormat = .ZPixmap,
    length: u16 = (@sizeOf(@This()) / 4),
    drawable_id: u32,
    graphic_context_id: u32,
    width: u16,
    height: u16,
    x: i16,
    y: i16,
    left_pad: u8 = 0,
    depth: u8,
    pad: [2]u8 = .{ 0, 0 },
};

pub const ImageFormat = enum(u8) {
    XYBitmap = 0,
    XYPixmap = 1,
    ZPixmap = 2,
};

pub const ClearArea = extern struct {
    opcode: u8 = 61,
    exposures: u8 = 0,
    length: u16 = (@sizeOf(@This()) / 4),
    window_id: u32,
    x: i16 = 0,
    y: i16 = 0,
    width: u16 = 0,
    height: u16 = 0,
};

pub const CopyArea = extern struct {
    opcode: u8 = 62,
    pad: u8 = 0,
    length: u16 = (@sizeOf(@This()) / 4),
    src_drawable_id: u32,
    dst_drawable_id: u32,
    graphic_context_id: u32,
    src_x: i16 = 0,
    src_y: i16 = 0,
    dst_x: i16 = 0,
    dst_y: i16 = 0,
    width: u16,
    height: u16,
};

pub const ErrorMessage = extern struct {
    message_code: u8, // already read to know it is an error
    error_code: ErrorCodes,
    sequence_number: u16,
    details: u32,
    minor_opcode: u16,
    major_opcode: u8,
    pad: [21]u8, // error messages always have 32 bytes total
};

pub const ErrorCodes = enum(u8) {
    NoError, // ??
    Request,
    Value,
    Window,
    Pixmap,
    Atom,
    Cursor,
    Font,
    Match,
    Drawable,
    Access,
    Alloc,
    Colormap,
    GContext,
    IDChoice,
    Name,
    Length,
    Implementation,
};

pub const KeyPress = extern struct {
    code: u8 = 2,
    keycode: u8,
    sequence_number: u16,
    time: u32,
    root: u32,
    event: u32,
    child: u32,
    root_x: i16,
    root_y: i16,
    event_x: i16,
    event_y: i16,
    state: u16,
    same_screen: u8, // actually a bool
    pad: [1]u8,
};

pub const KeyRelease = extern struct {
    code: u8 = 3,
    keycode: u8,
    sequence_number: u16,
    time: u32,
    root: u32,
    event: u32,
    child: u32,
    root_x: i16,
    root_y: i16,
    event_x: i16,
    event_y: i16,
    state: u16,
    same_screen: u8, // actually a bool
    pad: [1]u8,
};

pub const ButtonPress = extern struct {
    code: u8 = 4,
    keycode: u8,
    sequence_number: u16,
    time: u32,
    root: u32,
    event: u32,
    child: u32,
    root_x: i16,
    root_y: i16,
    event_x: i16,
    event_y: i16,
    state: u16,
    same_screen: u8, // actually a bool
    pad: [1]u8,
};

pub const ButtonRelease = extern struct {
    code: u8 = 5,
    keycode: u8,
    sequence_number: u16,
    time: u32,
    root: u32,
    event: u32,
    child: u32,
    root_x: i16,
    root_y: i16,
    event_x: i16,
    event_y: i16,
    state: u16,
    same_screen: u8, // actually a bool
    pad: [1]u8,
};

pub const Expose = extern struct {
    code: u8 = 12,
    window_id: u32,
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    minor_opcode: u16,
    count: u16,
    major_opcode: u8,
};

pub const GraphicsExposure = extern struct {
    code: u8 = 13,
    drawable_id: u32,
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    count: u16,
};

pub const NoExposure = extern struct {
    code: u8 = 14,
    drawable_id: u32,
    minor_opcode: u16,
    major_opcode: u8,
    //pad1: [24]u8,
};
