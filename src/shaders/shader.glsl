@vs vs
in vec4 position;
in vec4 color0;
in vec2 uv0;

out vec4 color;
out vec2 uv;

void main() {
    gl_Position = position;
    color = color0;
    uv = uv0;
}
@end

@fs fs
in vec4 color;
in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program game vs fs
