const std = @import("std");
const math = std.math;

pub const Vec2 = extern struct {
    x: f32,
    y: f32,
};

pub const Vec3 = extern struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const Vec4 = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn zero() Vec4 {
        return .{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 0.0 };
    }

    pub fn dehomogenize(self: Vec4) Vec4 {
        var ret = self;

        if (ret.w == 0.0) return .{
            .x = 0.0,
            .y = 0.0,
            .z = 0.0,
            .w = 1.0,
        };

        ret.x /= self.w;
        ret.y /= self.w;
        ret.z /= self.w;
        ret.w = 1.0;

        return ret;
    }
};

pub const Mat3 = extern struct {
    m: [3][3]f32,
};

pub const Mat4 = extern struct {
    m: [4][4]f32,

    pub fn mul(self: Mat4, mat: Mat4) Mat4 {
        var ret: Mat4 = undefined;

        for (0..4) |col| {
            for (0..4) |row| {
                ret.m[col][row] =
                    self.m[0][row] * mat.m[col][0] +
                    self.m[1][row] * mat.m[col][1] +
                    self.m[2][row] * mat.m[col][2] +
                    self.m[3][row] * mat.m[col][3];
            }
        }

        return ret;
    }
};
