const proto = @import("proto.zig");

// util to listen to all events
pub const EventMaskAll = blk: {
    var all: u32 = 0;
    const masks = @typeInfo(proto.EventMask).Enum.fields;
    for (masks) |mask| {
        all |= mask.value;
    }
    all ^= @intFromEnum(proto.EventMask.ResizeRedirect);
    all ^= @intFromEnum(proto.EventMask.SubstructureRedirect);
    all ^= @intFromEnum(proto.EventMask.OwnerGrabButton);
    break :blk all;
};

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
