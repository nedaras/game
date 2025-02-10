const std = @import("std");
const sokol = @import("sokol");
const shader = @import("shaders/shader.glsl.zig");
const math = @import("math.zig");

const gfx = sokol.gfx;
const app = sokol.app;
const glue = sokol.glue;

const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat3 = math.Mat3;
const Mat4 = math.Mat4;

var bind = gfx.Bindings{};
var pipe = gfx.Pipeline{};

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
        .type = .INDEXBUFFER,
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

    std.debug.print("Backend: {}\n", .{gfx.queryBackend()});
}

var time: f32 = 0;
export fn frame() void {
    defer gfx.commit();

    gfx.beginPass(.{ .swapchain = glue.swapchain() });
    defer gfx.endPass();

    const dt: f32 = @floatCast(app.frameDuration());
    time += @floatCast(app.frameDuration());

    var k_input = Vec2{
        .x = 0.0,
        .y = 0.0,
    };

    if (w_down) k_input.y += 1.0;
    if (s_down) k_input.y -= 1.0;

    if (a_down) k_input.x += 1.0;
    if (d_down) k_input.x -= 1.0;

    if (k_input.x != 0.0 or k_input.y != 0.0) {
        const l = @sqrt(k_input.x * k_input.x + k_input.y * k_input.y);
        k_input.x /= l;
        k_input.y /= l;
    }

    cam_vel.x += k_input.x * dt * 1000.0;
    cam_vel.z += k_input.y * dt * 1000.0;

    const speed = cam_vel.x * cam_vel.x + cam_vel.y * cam_vel.y + cam_vel.z * cam_vel.z;
    if (speed > 320.0) {
        cam_vel.x = (cam_vel.x / speed) * 320.0;
        cam_vel.z = (cam_vel.z / speed) * 320.0;
    }

    if (k_input.x == 0.0 and k_input.y == 0.0) {
        cam_vel.x -= cam_vel.x * 8.0 * dt;
        cam_vel.z -= cam_vel.z * 8.0 * dt;
    }

    cam_pos.x += cam_vel.x * dt;
    cam_pos.z += cam_vel.z * dt;

    const a = app.heightf() / app.widthf();
    const f = 1.0 / @tan(std.math.degreesToRadians(90.0 * 0.5));
    const near = 0.1;
    const far = 100.0;

    // column-major order
    const proj_mat = Mat4{ .m = .{
        .{ a * f, 0.0, 0.0, 0.0 },
        .{ 0.0, f, 0.0, 0.0 },
        .{ 0.0, 0.0, (far + near) / (far - near), -1.0 },
        .{ 0.0, 0.0, (2.0 * far * near) / (far - near), 0.0 },
    } };

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
        .{ cam_pos.x, cam_pos.y, cam_pos.z, 1.0 },
    } };

    const view_mat = rotation.mul(translation);
    const params = shader.VsParams{
        .proj_view = proj_mat.mul(view_mat),
        .model = .{ .m = .{
            .{ @cos(time), 0.0, -@sin(time), 0.0 },
            .{ 0.0, 1.0, 0.0, 0.0 },
            .{ @sin(time), 0.0, @cos(time), 0.0 },
            .{ @sin(time * 2.5), @sin(time), -8.0, 1.0 },
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

var cam_pos = Vec3{
    .x = 0.0,
    .y = 0.0,
    .z = 0.0,
};

var cam_vel = Vec3{
    .x = 0.0,
    .y = 0.0,
    .z = 0.0,
};

var w_down = false;
var a_down = false;
var s_down = false;
var d_down = false;

export fn input(event: ?*const app.Event) void {
    const ev = event.?;
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
        .event_cb = input,
        .width = 512,
        .height = 512,
        .icon = .{ .sokol_default = true },
        .window_title = "game",
        .logger = .{ .func = sokol.log.func },
        .win32_console_attach = true,
    });
}
