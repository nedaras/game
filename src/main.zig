const std = @import("std");
const sokol = @import("sokol");
const shader = @import("shaders/shader.glsl.zig");
const math = @import("math.zig");
const vec = @import("vec.zig");
const mat = @import("mat.zig");

const gfx = sokol.gfx;
const app = sokol.app;
const glue = sokol.glue;

const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3 = math.Mat3;
const Mat4 = math.Mat4;

var bind = gfx.Bindings{};
var pipe = gfx.Pipeline{};

const state = struct {
    var player_vel = vec.zero(3);
    var player_pos = vec.zero(3);
};

export fn init() void {
    gfx.setup(.{
        .environment = glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    bind.vertex_buffers[0] = gfx.makeBuffer(.{
        .data = gfx.asRange(&[_]f32{
            -1.0, -1.0, 1.0,  1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
            -1.0, 1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 0.0, 0.0, 1.0,

            -1.0, 1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  1.0,  -1.0, 0.0, 1.0, 0.0, 1.0,
            -1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
            1.0,  -1.0, -1.0, 0.0, 0.0, 0.0, 1.0,

            -1.0, 1.0,  1.0,  1.0, 0.0, 0.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 1.0, 0.0, 1.0,
            -1.0, 1.0,  -1.0, 0.0, 0.0, 1.0, 1.0,
            1.0,  1.0,  -1.0, 0.0, 0.0, 0.0, 1.0,

            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, -1.0, 0.0, 1.0, 0.0, 1.0,
            -1.0, -1.0, 1.0,  0.0, 0.0, 1.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 0.0, 0.0, 1.0,

            1.0,  -1.0, 1.0,  1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, -1.0, 0.0, 1.0, 0.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            1.0,  1.0,  -1.0, 0.0, 0.0, 0.0, 1.0,

            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            -1.0, -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
            -1.0, 1.0,  -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0, 1.0,  1.0,  0.0, 0.0, 0.0, 1.0,
        }),
    });

    bind.index_buffer = gfx.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = gfx.asRange(&[_]u16{ // CW
            0,  2,  1,
            2,  3,  1,

            4,  6,  5,
            6,  7,  5,

            8,  10, 9,
            10, 11, 9,

            12, 14, 13,
            14, 15, 13,

            16, 18, 17,
            18, 19, 17,

            20, 22, 21,
            22, 23, 21,
        }),
    });

    pipe = gfx.makePipeline(.{
        .shader = gfx.makeShader(shader.gameShaderDesc(gfx.queryBackend())),
        .layout = blk: {
            var l = gfx.VertexLayoutState{};
            l.attrs[shader.ATTR_game_pos].format = .FLOAT3;
            l.attrs[shader.ATTR_game_color0].format = .FLOAT4;
            break :blk l;
        },
        .index_type = .UINT16,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .BACK,
    });
}

inline fn floatFromBool(comptime T: type, value: bool) T {
    return @floatFromInt(@intFromBool(value));
}

var time: f32 = 0;
export fn frame() void {
    defer gfx.commit();

    gfx.beginPass(.{ .swapchain = glue.swapchain() });
    defer gfx.endPass();

    const dt: f32 = @floatCast(app.frameDuration());
    time += @floatCast(app.frameDuration());

    var input = vec.new(.{
        floatFromBool(f32, a_down) - floatFromBool(f32, d_down),
        0.0,
        floatFromBool(f32, w_down) - floatFromBool(f32, s_down),
    });

    if (!vec.eql(input, vec.zero(3))) {
        const inv_l = vec.invLen(input);
        input *= vec.fill(3, inv_l);
    }

    state.player_vel += input * vec.fill(3, dt * 1000.0);

    const speed = vec.len2(state.player_vel);
    if (speed > 320.0) {
        state.player_vel = state.player_vel / vec.fill(3, speed) * vec.fill(3, 320.0);
    }

    if (vec.eql(input, vec.zero(3))) {
        state.player_vel -= state.player_vel * vec.fill(3, 8.0 * dt);
    }

    state.player_pos += state.player_vel * vec.fill(3, dt);

    const a = app.heightf() / app.widthf();
    const f = 1.0 / @tan(std.math.degreesToRadians(90.0 * 0.5));
    const near = 0.1;
    const far = 100.0;

    // column-major order
    const proj_mat = Mat4{ .m = .{
        .{ a * f, 0.0, 0.0, 0.0 },
        .{ 0.0, f, 0.0, 0.0 },
        .{ 0.0, 0.0, (far + near) / (near - far), -1.0 },
        .{ 0.0, 0.0, (2.0 * far * near) / (near - far), 0.0 },
    } };

    const pm = mat.new(.{
        .{ a * f, 0.0 },
        .{ 0.0, 1.0 },
        .{ 0.0, 1.0 },
    });
    std.debug.print("{d}\n", .{pm.mat});

    const rotation = Mat4{ .m = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ 0.0, 0.0, 0.0, 1.0 },
    } };

    const translation = Mat4{ .m = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ state.player_pos[vec.x], 0.0, state.player_pos[vec.z] - 6.0, 1.0 },
    } };

    const view_mat = rotation.mul(translation);
    const params = shader.VsParams{
        .proj_view = proj_mat.mul(view_mat),
        .model = .{ .m = .{
            .{ 1.0, 0.0, 0.0, 0.0 },
            .{ 0.0, @cos(time), @sin(time), 0.0 },
            .{ 0.0, -@sin(time), @cos(time), 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        } },
    };

    gfx.applyPipeline(pipe);
    gfx.applyBindings(bind);
    gfx.applyUniforms(shader.UB_vs_params, gfx.asRange(&params));
    gfx.draw(0, 36, 1);
}

export fn cleanup() void {
    gfx.shutdown();
}

var w_down = false;
var a_down = false;
var s_down = false;
var d_down = false;

export fn event(e: ?*const app.Event) void {
    const ev = e.?;
    if (ev.type == .KEY_DOWN or ev.type == .KEY_UP) {
        const down = ev.type == .KEY_DOWN;

        switch (ev.key_code) {
            .W => w_down = down,
            .S => s_down = down,
            .A => a_down = down,
            .D => d_down = down,
            else => {},
        }
    }
}

pub fn main() void {
    app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "game",
        .logger = .{ .func = sokol.log.func },
        .win32_console_attach = true,
    });
}
