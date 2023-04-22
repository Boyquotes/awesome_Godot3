shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform sampler2D main_texture;
uniform vec4 color : hint_color;

void fragment() {
	ALBEDO = texture(main_texture, UV).rgb*color.rgb;
	ALPHA = pow(1.0 - NORMAL.z, 2)*color.a;
}