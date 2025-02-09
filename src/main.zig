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

    time += @floatCast(app.frameDuration());

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
            .{ @sin(time * 2.5), @sin(time), 0.0, 1.0 },
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

export fn input(event: ?*const app.Event) void {
    const ev = event.?;
    if (ev.type == .KEY_DOWN) {
        switch (ev.key_code) {
            .W => cam_pos.z += 0.25,
            .S => cam_pos.z -= 0.25,
            .A => cam_pos.x += 0.25,
            .D => cam_pos.x -= 0.25,
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
