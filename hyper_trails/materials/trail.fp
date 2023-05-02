varying lowp vec4 var_tint;
varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture0;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(var_tint.xyz * var_tint.w, var_tint.w);
    gl_FragColor = texture2D(texture0, var_texcoord0.xy) * tint_pm;
}
