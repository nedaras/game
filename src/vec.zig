pub const x = 0;
pub const y = 1;
pub const z = 2;
pub const w = 3;

// need so compile stuff for this like max len 4 and only f32
pub inline fn zero(comptime l: comptime_int) @Vector(l, f32) {
    return @splat(0.0);
}

pub inline fn fill(comptime l: comptime_int, val: f32) @Vector(l, f32) {
    return @splat(val);
}

pub inline fn eql(a: anytype, b: anytype) bool {
    return @reduce(.And, a == b);
}

pub fn invLen(a: anytype) f32 {
    const l = @reduce(.Add, a * a);
    const th = 1.5;

    var out = l;
    var i: u32 = @bitCast(out);
    i = 0x5f3759df - (i >> 1);
    out = @bitCast(i);
    out = out * (th - (0.5 * l * out * out));

    return out;
}

pub inline fn len(a: anytype) f32 {
    return @sqrt(@reduce(.Add, a * a));
}

pub inline fn len2(a: anytype) f32 {
    return @reduce(.Add, a * a);
}

pub inline fn new(args: anytype) @Vector(@typeInfo(@TypeOf(args)).@"struct".fields.len, f32) {
    return args;
}

fn vectorLength(comptime VectorType: type) comptime_int {
    return switch (@typeInfo(VectorType)) {
        .vector => |info| info.len,
        .array => |info| info.len,
        else => @compileError("Invalid type " ++ @typeName(VectorType)),
    };
}
