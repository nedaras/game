const std = @import("std");

pub const Vector2D = extern struct {
    x: f32,
    y: f32,
};

pub const Vector3D = extern struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn zero() Vector3D {
        return .{
            .x = 0.0,
            .y = 0.0,
            .z = 0.0,
        };
    }

    pub fn up() Vector3D {
        return .{
            .x = 0.0,
            .y = 1.0,
            .z = 0.0,
        };
    }

    pub fn left() Vector3D {
        return .{
            .x = 1.0,
            .y = 0.0,
            .z = 0.0,
        };
    }

    pub fn len(v: Vector3D) f32 {
        return @sqrt(dot(v, v));
    }

    pub fn cross(v0: Vector3D, v1: Vector3D) Vector3D {
        return .{
            .x = (v0.y * v1.z) - (v0.z * v1.y),
            .y = (v0.z * v1.x) - (v0.x * v1.z),
            .z = (v0.x * v1.y) - (v0.y * v1.x),
        };
    }

    pub fn dot(v0: Vector3D, v1: Vector3D) f32 {
        return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
    }

    pub fn sub(v0: Vector3D, v1: Vector3D) Vector3D {
        return .{
            .x = v0.x - v1.x,
            .y = v0.y - v1.y,
            .z = v0.z - v1.z,
        };
    }

    pub fn normalize(v: Vector3D) Vector3D {
        const l = len(v);
        std.debug.assert(l != 0.0);
        return .{
            .x = v.x / l,
            .y = v.y / l,
            .z = v.z / l,
        };
    }
};
