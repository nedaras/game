const mat = @import("mat.zig");
const vec = @import("vec.zig");

pub const x = 0;
pub const y = 1;
pub const z = 2;
pub const w = 3;

pub inline fn new(args: [4]f32) @Vector(4, f32) {
    return args;
}

pub inline fn inv(quat: @Vector(4, f32)) @Vector(4, f32) {
    return quat * @Vector(4, f32){ -1.0, -1.0, -1.0, 1.0 };
}

pub fn toMat(quat: @Vector(4, f32)) mat.Mat(4, 4) {
    @setRuntimeSafety(false);

    const q2 = quat + quat;
    const qq = quat * q2;

    const xx = qq[x];
    const yy = qq[y];
    const zz = qq[z];

    const xy = quat[x] * q2[y];
    const xz = quat[x] * q2[z];
    const yz = quat[y] * q2[z];

    const wx = quat[w] * q2[x];
    const wy = quat[w] * q2[y];
    const wz = quat[w] * q2[z];

    return mat.new(.{
        .{ 1.0 - (yy + zz), xy - wz, xz + wy, 0.0 },
        .{ xy + wz, 1.0 - (xx + zz), yz - wx, 0.0 },
        .{ xz - wy, yz + wx, 1.0 - (xx + yy), 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    });
}

pub fn mul(a: @Vector(4, f32), b: @Vector(4, f32)) @Vector(4, f32) { // tofo: cmon simd
    @setRuntimeSafety(false);

    return .{
        a[w] * b[x] + a[x] * b[w] + a[y] * b[z] - a[z] * b[y],
        a[w] * b[y] - a[x] * b[z] + a[y] * b[w] + a[z] * b[x],
        a[w] * b[z] + a[x] * b[y] - a[y] * b[x] + a[z] * b[w],
        a[w] * b[w] - a[x] * b[x] - a[y] * b[y] - a[z] * b[z],
    };
}
