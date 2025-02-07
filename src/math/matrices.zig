const std = @import("std");
const Vector3D = @import("vectors.zig").Vector3D;

pub const Matrix4x4 = extern struct {
    m: [4][4]f32,

    pub fn zero() Matrix4x4 {
        return .{ .m = [4][4]f32{
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 0.0 },
        } };
    }

    pub fn identity() Matrix4x4 {
        return .{ .m = [4][4]f32{
            .{ 1.0, 0.0, 0.0, 0.0 },
            .{ 0.0, 1.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        } };
    }

    pub fn mul(m0: Matrix4x4, m1: Matrix4x4) Matrix4x4 {
        var m: Matrix4x4 = undefined;

        inline for (0..4) |col| {
            inline for (0..4) |row| {
                m.m[col][row] =
                    m0.m[0][row] * m1.m[col][0] +
                    m0.m[1][row] * m1.m[col][1] +
                    m0.m[2][row] * m1.m[col][2] +
                    m0.m[3][row] * m1.m[col][3];
            }
        }

        return m;
    }

    pub fn persp(fov: f32, aspect: f32, near: f32, far: f32) Matrix4x4 {
        var m: Matrix4x4 = undefined;
        const t = @tan(fov * (std.math.pi / 360.0));
        m.m[0][0] = 1.0 / t;
        m.m[1][1] = aspect / t;
        m.m[2][3] = -1.0;
        m.m[2][2] = (near + far) / (near - far);
        m.m[3][2] = (2.0 * near * far) / (near - far);
        m.m[3][3] = 0.0;
        return m;
    }

    pub fn lookat(eye: Vector3D, center: Vector3D, up: Vector3D) Matrix4x4 {
        var m: Matrix4x4 = zero();

        const f = center.sub(eye).normalize();
        const s = f.cross(up).normalize();
        const u = s.cross(f);

        m.m[0][0] = s.x;
        m.m[0][1] = u.x;
        m.m[0][2] = -f.x;

        m.m[1][0] = s.y;
        m.m[1][1] = u.y;
        m.m[1][2] = -f.y;

        m.m[2][0] = s.z;
        m.m[2][1] = u.z;
        m.m[2][2] = -f.z;

        m.m[3][0] = -s.dot(eye);
        m.m[3][1] = -u.dot(eye);
        m.m[3][2] = f.dot(eye);
        m.m[3][3] = 1.0;

        return m;
    }

    pub fn rotate(rads: f32, axis: Vector3D) Matrix4x4 {
        // todo: assert for one
        var m: Matrix4x4 = identity();

        const sin_theta = @sin(rads);
        const cos_theta = @cos(rads);
        const cos_value = 1.0 - cos_theta;

        m.m[0][0] = (axis.x * axis.x * cos_value) + cos_theta;
        m.m[0][1] = (axis.x * axis.y * cos_value) + (axis.z * sin_theta);
        m.m[0][2] = (axis.x * axis.z * cos_value) - (axis.y * sin_theta);
        m.m[1][0] = (axis.y * axis.x * cos_value) - (axis.z * sin_theta);
        m.m[1][1] = (axis.y * axis.y * cos_value) + cos_theta;
        m.m[1][2] = (axis.y * axis.z * cos_value) + (axis.x * sin_theta);
        m.m[2][0] = (axis.z * axis.x * cos_value) + (axis.y * sin_theta);
        m.m[2][1] = (axis.z * axis.y * cos_value) - (axis.x * sin_theta);
        m.m[2][2] = (axis.z * axis.z * cos_value) + cos_theta;

        return m;
    }
};
