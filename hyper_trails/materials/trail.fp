#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_tint;

uniform lowp sampler2D texture0;

out lowp vec4 frag_color;

void main()
{
    frag_color = texture(texture0, var_texcoord0.xy) * var_tint;
}
