#version 150

in vec2 Texcoord;
in vec3 Color;

out vec4 outColor;

uniform sampler2D tex;

void main()
{
    if (Texcoord.y < 0.5)
    {
        outColor = texture(tex, Texcoord) * vec4(Color, 1.0);
    }
    else
    {
        outColor = texture(tex, vec2(Texcoord.x, 1.0 - Texcoord.y)) * vec4(Color, 1.0);
    }
}
