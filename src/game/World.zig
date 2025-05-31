const std = @import("std");
const fastnoise = @import("../fastnoise.zig"); // todo: i want to make my own noise func
const Allocator = std.mem.Allocator;

const Noise = fastnoise.Noise(f32);

const Vertex = extern struct {
    x: f32,
    y: f32,
    z: f32,
    color: u32,
};

const resolution = 12;

noise: Noise,
verticies: [(resolution + 1) * (resolution + 1)]Vertex,
indecies: [resolution * resolution * 6]u16,

const Self = @This();

pub const Options = struct {
    seed: i32,
};

pub fn init(options: Options) Self {
    @setEvalBranchQuota(100000);
    var world = Self{
        .noise = .{
            .seed = options.seed,
            .noise_type = .cellular,
            .frequency = 0.25,
            .gain = 0.40,
            .fractal_type = .fbm,
            .lacunarity = 0.40,
            .cellular_distance = .euclidean,
            .cellular_return = .distance2,
            .cellular_jitter_mod = 0.88,
        },
        .verticies = undefined,
        .indecies = undefined,
    };

    world.update(0.0, 0.0);

    for (0..resolution) |y| {
        for (0..resolution) |x| {
            const tl: u16 = @intCast(y * (resolution + 1) + x);
            const tr: u16 = @intCast(y * (resolution + 1) + x + 1);
            const bl: u16 = @intCast((y + 1) * (resolution + 1) + x);
            const br: u16 = @intCast((y + 1) * (resolution + 1) + x + 1);

            const i = (y * resolution + x) * 6;

            world.indecies[i + 0] = tl;
            world.indecies[i + 1] = bl;
            world.indecies[i + 2] = br;

            world.indecies[i + 3] = tl;
            world.indecies[i + 4] = br;
            world.indecies[i + 5] = tr;
        }
    }

    return world;
}

pub fn update(self: *Self, x: f32, y: f32) void {
    for (0..resolution + 1) |iy| {
        for (0..resolution + 1) |ix| {
            const fx: f32 = @floatFromInt(ix);
            const fy: f32 = @floatFromInt(iy);
            const height = self.noise.genNoise2D(fx + x, fy + y);

            const norm_height: u32 = @intFromFloat((height + 1.0) * 0.5 * 255.0);
            const gray = (0xFF << 24) | (norm_height << 16) | (norm_height << 8) | norm_height;

            self.verticies[iy * (resolution + 1) + ix] = .{ .x = fx, .y = fy, .z = height, .color = gray };
        }
    }
}
