shader_type spatial;
render_mode blend_add,cull_disabled,unshaded,world_vertex_coords;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;

uniform vec3 world_player;
uniform float min_distance = 2.0;
uniform float max_distance = 5.0;
uniform bool debug = false;

varying float offset;

void vertex() {
	float d;
	if (debug) {
		d = 0.0;
	}
	else {
		d = length(world_player - VERTEX);
	}
	offset = clamp((d-min_distance)/(max_distance-min_distance), 0, 1);
}

void fragment() {
	float brightness = clamp(texture(texture_albedo,UV).r - offset, 0, 1);
	ALBEDO = albedo.rgb * brightness;
}
