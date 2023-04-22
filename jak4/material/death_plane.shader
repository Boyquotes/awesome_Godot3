shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, world_vertex_coords;

uniform float max_depth;
uniform vec4 depth_color: hint_color;

varying vec3 pos;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	float depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	vec4 wpos = CAMERA_MATRIX*upos;
	vec3 pixel_position = wpos.xyz / wpos.w;
	
	float diffy = pos.y - pixel_position.y;
	
	float amount = clamp(diffy/max_depth, 0, 1);
	
	ALBEDO = depth_color.rgb;
	ALPHA = amount;
}