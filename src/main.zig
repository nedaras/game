const std = @import("std");
const sokol = @import("sokol");
const shader = @import("shaders/shader.glsl.zig");
const math = @import("math.zig");

const gfx = sokol.gfx;
const app = sokol.app;
const glue = sokol.glue;

const Vector2D = math.Vector2D;
const Vector3D = math.Vector3D;
const Matrix4x4 = math.Matrix4x4;

var bind = gfx.Bindings{};
var pipe = gfx.Pipeline{};

var pass_action = gfx.PassAction{};

var rotation: f32 = 0.0;

const view_matrix = Matrix4x4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, Vector3D.zero(), Vector3D.up());

export fn init() void {
    gfx.setup(.{
        .environment = glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    bind.vertex_buffers[0] = gfx.makeBuffer(.{
        .data = gfx.asRange(&[_]f32{
            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, -1.0, 0.0, 1.0, 0.0, 1.0,
            1.0,  1.0,  -1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0, 1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,

            -1.0, -1.0, 1.0,  1.0, 0.0, 0.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            -1.0, 1.0,  1.0,  1.0, 0.0, 0.0, 1.0,

            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            -1.0, 1.0,  -1.0, 0.0, 1.0, 0.0, 1.0,
            -1.0, 1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            -1.0, -1.0, 1.0,  1.0, 0.0, 0.0, 1.0,

            1.0,  -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            1.0,  1.0,  -1.0, 0.0, 1.0, 0.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            1.0,  -1.0, 1.0,  1.0, 0.0, 0.0, 1.0,

            -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
            -1.0, -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
            1.0,  -1.0, 1.0,  0.0, 0.0, 1.0, 1.0,
            1.0,  -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,

            -1.0, 1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,
            -1.0, 1.0,  1.0,  0.0, 1.0, 0.0, 1.0,
            1.0,  1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
            1.0,  1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,
        }),
    });

    bind.index_buffer = gfx.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = gfx.asRange(&[_]u16{
            0,  1,  2,  0,  2,  3,
            6,  5,  4,  7,  6,  4,
            8,  9,  10, 8,  10, 11,
            14, 13, 12, 15, 14, 12,
            16, 17, 18, 16, 18, 19,
            22, 21, 20, 23, 22, 20,
        }),
    });

    pipe = gfx.makePipeline(.{
        // this is not in comptime :(
        .shader = gfx.makeShader(shader.gameShaderDesc(gfx.queryBackend())),
        .index_type = .UINT16,
        .layout = blk: {
            var l = gfx.VertexLayoutState{};
            l.attrs[shader.ATTR_game_position].format = .FLOAT3;
            l.attrs[shader.ATTR_game_color0].format = .FLOAT4;
            break :blk l;
        },
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .BACK,
    });

    pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.25, .g = 0.5, .b = 0.75, .a = 1 } };
    std.debug.print("Backend: {}\n", .{gfx.queryBackend()});
}

export fn frame() void {
    defer gfx.commit();

    gfx.beginPass(.{ .action = pass_action, .swapchain = glue.swapchain() });
    defer gfx.endPass();

    rotation += @floatCast(app.frameDuration());

    const aspect = app.widthf() / app.heightf();
    const projection_matrix = Matrix4x4.persp(90.0, aspect, 0.01, 10.0);
    const model_matrix = Matrix4x4.rotate(rotation, Vector3D.up()); // up is not up?

    gfx.applyPipeline(pipe);
    gfx.applyBindings(bind);
    gfx.applyUniforms(shader.UB_vs_params, gfx.asRange(&shader.VsParams{
        .mvp = projection_matrix.mul(view_matrix).mul(model_matrix),
    }));

    gfx.draw(0, 36, 1);
}

export fn cleanup() void {
    gfx.shutdown();
}

pub fn main() void {
    app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 640,
        .height = 480,
        .icon = .{ .sokol_default = true },
        .window_title = "game",
        .logger = .{ .func = sokol.log.func },
        .win32_console_attach = true,
    });
}
