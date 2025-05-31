@ctype mat4 [4][4]f32

@vs vs
layout(binding = 0) uniform vs_params {
    mat4 view_proj;
    mat4 model;
};

in vec3 pos;
in vec4 color0;

out vec4 color;

void main() {
  gl_Position = view_proj * model * vec4(pos, 1.0);
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
