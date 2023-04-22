shader_type spatial;
render_mode world_vertex_coords, cull_front, depth_test_disable, unshaded, blend_mul;

stencil {
	value 0;
	test equal;
}

uniform vec4 surface_albedo : hint_color;
uniform vec4 deep_albedo : hint_color;
uniform float max_depth : hint_range(0.1, 100.0) = 5.0;

void fragment() {
	float depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	float f = clamp(upos.w, 0.0, 1.0);
	ALBEDO = mix(deep_albedo.rgb,surface_albedo.rgb, f);
}