#version 150

in vec2 Texcoord;
in vec3 Color;

out vec4 outColor;

uniform sampler2D tex1;
uniform sampler2D tex2;

void main()
{
    outColor = mix(texture(tex1, Texcoord), texture(tex2, Texcoord), 0.5);
}
