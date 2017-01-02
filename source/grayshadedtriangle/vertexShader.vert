#version 150

in vec2 position;
in float shade;

out float Shade;

void main()
{
    gl_Position = vec4(position, 0.0, 1.0);
    Shade = shade;
}
