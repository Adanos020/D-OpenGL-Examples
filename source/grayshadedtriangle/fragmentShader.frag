#version 150

in float Shade;

out vec4 outColor;

void main()
{
    outColor = vec4(Shade, Shade, Shade, 1.0);
}
