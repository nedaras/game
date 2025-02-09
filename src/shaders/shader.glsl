@header const m = @import("../math.zig")
@ctype mat4 m.Mat4

@vs vs
layout(binding = 0) uniform vs_params {
    mat4 proj_view;
    mat4 model;
};

in vec3 pos;
in vec4 color0;

out vec4 color;

void main() {
    mat4 mat = proj_view * model;
    vec4 out0 = vec4(pos, 1.0) * mat;

    gl_Position = vec4(out0.xyz, 1.0);
    color = color0;
}
@end

@fs fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program game vs fs
