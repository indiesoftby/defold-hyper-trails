varying lowp vec4 var_tint;
varying mediump vec2 var_texcoord0;

uniform highp sampler2D texture0;
uniform lowp sampler2D texture1;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    // lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
    // gl_FragColor = texture2D(texture_sampler, var_texcoord0.xy) * tint_pm;

    // gl_FragColor = vec4(var_color.x, (var_color.y + 0.5), 0.0, 1.0);
    // gl_FragColor = vec4(var_texcoord0.x, var_texcoord0.y, 0.0, 1.0);
    // gl_FragColor = vec4(1.0,0.0,1.0,1.0);
    //gl_FragColor = texture2D(texture0, vec2(var_color.x, (var_color.y + 0.5)));
    //gl_FragColor = vec4(var_color.x, var_color.y, var_color.z, 1.0); // texture2D(texture0, var_texcoord0);
    //gl_FragColor = vec4(0.25,0.25,0.25,0.5);

    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(var_tint.xyz * var_tint.w, var_tint.w);
    gl_FragColor = texture2D(texture1, var_texcoord0.xy) * tint_pm;
    // gl_FragColor = var_color;
}
