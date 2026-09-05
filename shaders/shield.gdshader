shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;
uniform vec4 tint : source_color = vec4(0.1,0.7,1.0,0.3);
void fragment() {
 float edge=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),3.0);
 float bands=0.75+0.25*sin(VERTEX.y*28.0+TIME*1.5);
 ALBEDO=tint.rgb;
 EMISSION=tint.rgb*1.3;
 ALPHA=edge*tint.a*bands;
}
