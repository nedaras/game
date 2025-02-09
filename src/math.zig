const std = @import("std");
const math = std.math;

pub const Vec2 = extern struct {};

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

        for (0..4) |row| {
            for (0..4) |col| {
                ret.m[row][col] =
                    self.m[row][0] * mat.m[0][col] +
                    self.m[row][1] * mat.m[1][col] +
                    self.m[row][2] * mat.m[2][col] +
                    self.m[row][3] * mat.m[3][col];
            }
        }

        return ret;
    }
};
