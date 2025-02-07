const std = @import("std");
const sokol = @import("sokol");
const gfx = sokol.gfx;
const app = sokol.app;
const glue = sokol.glue;

var bind = gfx.Bindings{};
var pipe = gfx.Pipeline{};

export fn init() void {
    gfx.setup(.{
        .environment = glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    bind.vertex_buffers[0] = gfx.makeBuffer(.{
        .data = gfx.asRange(&[_]f32{
            -1.0, 1.0,  0.5, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0,
            -1.0, -1.0, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0,
            1.0,  -1.0, 0.5, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0,
            1.0,  1.0,  0.5, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0,
        }),
    });

    bind.index_buffer = gfx.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = gfx.asRange(&[_]u16{
            0, 1, 2,
            2, 3, 0,
        }),
    });

    const shader = @import("shaders/shader.glsl.zig");
    pipe = gfx.makePipeline(.{
        // this is not in comptime :(
        .shader = gfx.makeShader(shader.gameShaderDesc(gfx.queryBackend())),
        .index_type = .UINT16,
        .layout = blk: {
            var l = gfx.VertexLayoutState{};
            l.attrs[shader.ATTR_game_position].format = .FLOAT3;
            l.attrs[shader.ATTR_game_color0].format = .FLOAT4;
            l.attrs[shader.ATTR_game_uv0].format = .FLOAT2;
            break :blk l;
        },
    });

    std.debug.print("Backend: {}\n", .{gfx.queryBackend()});
}

export fn frame() void {
    defer gfx.commit();

    gfx.beginPass(.{ .swapchain = glue.swapchain() });
    defer gfx.endPass();

    gfx.applyPipeline(pipe);
    gfx.applyBindings(bind);

    gfx.draw(0, 6, 1);

    //const g = state.pass_action.colors[0].clear_value.g + 0.01;
    //state.pass_action.colors[0].clear_value.g = if (g > 1.0) 0.0 else g;
    //gfx.beginPass(.{ .action = state.pass_action, .swapchain = glue.swapchain() });
    //gfx.endPass();
    //gfx.commit();
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
