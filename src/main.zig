const std = @import("std");
const math = std.math;
const sokol = @import("sokol");
const shader = @import("shaders/shader.glsl.zig");
const vec = @import("vec.zig");
const mat = @import("mat.zig");
const quat = @import("quat.zig");

const gfx = sokol.gfx;
const app = sokol.app;
const glue = sokol.glue;

var bind = gfx.Bindings{};
var pipe = gfx.Pipeline{};

const Vertex = extern struct {
    x: f32,
    y: f32,
    z: f32,
    color: u32,
};

const state = struct {
    var cam_vel = vec.zero(3);
    var cam_pos = vec.new(.{ 0.0, 0.0, 6.0 });
};

export fn init() void {
    gfx.setup(.{
        .environment = glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    bind.vertex_buffers[0] = gfx.makeBuffer(.{
        .data = gfx.asRange(&[_]Vertex{
            .{ .x = 0.0, .y = 0.0, .z = 0.0, .color = 0xFF0000FF },
            .{ .x = 1.0, .y = 0.0, .z = 0.0, .color = 0xFF00FF00 },
            .{ .x = 2.0, .y = 0.0, .z = 0.0, .color = 0xFFFF0000 },

            .{ .x = 0.0, .y = 1.0, .z = 0.0, .color = 0xFF0000FF },
            .{ .x = 1.0, .y = 1.0, .z = 0.0, .color = 0xFF00FF00 },
            .{ .x = 2.0, .y = 1.0, .z = 0.0, .color = 0xFFFF0000 },

            .{ .x = 0.0, .y = 2.0, .z = 0.0, .color = 0xFF0000FF },
            .{ .x = 1.0, .y = 2.0, .z = 0.0, .color = 0xFF00FF00 },
            .{ .x = 2.0, .y = 2.0, .z = 0.0, .color = 0xFFFF0000 },
        })
    });

    bind.index_buffer = gfx.makeBuffer(.{
        .usage = .{ .index_buffer = true },
        .data = gfx.asRange(&[_]u16{ // CW
            4, 0, 3,
            4, 1, 0,

            5, 1, 4,
            5, 2, 1,

            7, 3, 6,
            7, 4, 3,

            8, 4, 7,
            8, 5, 4,
        }),
    });

    pipe = gfx.makePipeline(.{
        .shader = gfx.makeShader(shader.gameShaderDesc(gfx.queryBackend())),
        .layout = blk: {
            var l = gfx.VertexLayoutState{};
            l.attrs[shader.ATTR_game_pos].format = .FLOAT3;
            l.attrs[shader.ATTR_game_color0].format = .UBYTE4N;
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

export fn frame() void {
    defer gfx.commit();

    gfx.beginPass(.{ .swapchain = glue.swapchain() });
    defer gfx.endPass();

    const dt: f32 = @floatCast(app.frameDuration());

    var input = vec.new(.{
        floatFromBool(f32, d_down) - floatFromBool(f32, a_down),
        floatFromBool(f32, s_down) - floatFromBool(f32, w_down),
    });

    if (!vec.eql(input, vec.zero(2))) {
        const inv_l = vec.invLen(input);
        input *= vec.fill(2, inv_l);
    }

    const forward = vec.new(.{
        input[vec.x] * @cos(yaw) - input[vec.y] * @sin(yaw),
        0.0,
        input[vec.x] * @sin(yaw) + input[vec.y] * @cos(yaw),
    });

    state.cam_vel += forward * vec.fill(3, dt * 640.0);

    const speed = vec.len2(state.cam_vel);
    if (speed > 280.0) {
        state.cam_vel = state.cam_vel / vec.fill(3, speed) * vec.fill(3, 280.0);
    }

    if (vec.eql(input, vec.zero(2))) {
        state.cam_vel -= state.cam_vel * vec.fill(3, 12.0 * dt);
    }

    state.cam_pos += state.cam_vel * vec.fill(3, dt);

    const a = app.heightf() / app.widthf();
    const f = 1.0 / @tan(math.degreesToRadians(90.0 * 0.5));
    const near = 0.1;
    const far = 100.0;

    const proj_mat = mat.new(.{
        .{ a * f, 0.0, 0.0, 0.0 },
        .{ 0.0, f, 0.0, 0.0 },
        .{ 0.0, 0.0, (far + near) / (near - far), -1.0 },
        .{ 0.0, 0.0, (2.0 * far * near) / (near - far), 0.0 },
    });

    const yaw_quat = quat.new(.{ 0.0, @sin(yaw * 0.5), 0.0, @cos(yaw * 0.5) });
    const pitch_quat = quat.new(.{ @sin(pitch * 0.5), 0.0, 0.0, @cos(pitch * 0.5) });

    const rotation = quat.mul(pitch_quat, yaw_quat);
    const translation = mat.new(.{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ -state.cam_pos[vec.x], -state.cam_pos[vec.y], -state.cam_pos[vec.z], 1.0 },
    });

    const view_mat = mat.mul(quat.toMat(quat.inv(rotation)), translation);
    const params = shader.VsParams{ .view_proj = mat.mul(proj_mat, view_mat).mat, .model = .{
        .{ 1.0, 0.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0, 0.0 },
        .{ 0.0, 0.0, 1.0, 0.0 },
        .{ -1.0, -1.0, 0.0, 1.0 },
    } };

    gfx.applyPipeline(pipe);
    gfx.applyBindings(bind);
    gfx.applyUniforms(shader.UB_vs_params, gfx.asRange(&params));
    gfx.draw(0, 24, 1);
}

export fn cleanup() void {
    gfx.shutdown();
}

var w_down = false;
var a_down = false;
var s_down = false;
var d_down = false;

var yaw: f32 = 0.0;
var pitch: f32 = 0.0;

export fn event(e: ?*const app.Event) void {
    const ev = e orelse return;
    switch (ev.type) {
        .MOUSE_MOVE => {
            yaw += ev.mouse_dx * 0.002;
            pitch = @max(@min(pitch + ev.mouse_dy * 0.002, math.degreesToRadians(90)), math.degreesToRadians(-90));
        },
        .MOUSE_ENTER => {
            app.lockMouse(true);
        },
        .KEY_DOWN, .KEY_UP => {
            const down = ev.type == .KEY_DOWN;
            switch (ev.key_code) {
                .W => w_down = down,
                .S => s_down = down,
                .A => a_down = down,
                .D => d_down = down,
                else => {},
            }
        },
        else => {},
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
        .window_title = "rizz",
        .logger = .{ .func = sokol.log.func },
        .win32_console_attach = true,
    });
}
