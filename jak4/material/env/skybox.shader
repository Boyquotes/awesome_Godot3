shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never, skip_vertex_transform;

uniform sampler2D gradient;
uniform sampler2D gradient2;
uniform float blend : hint_range(0.0, 1.0);
varying float dir;

void vertex() {
	dir = NORMAL.y*0.5 + 0.5;
	VERTEX = (MODELVIEW_MATRIX*vec4(VERTEX, 0.0)).xyz;
	NORMAL = (MODELVIEW_MATRIX*vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec3 g1 = texture(gradient, vec2(dir, 0.0)).rgb;
	vec3 g2 = texture(gradient2, vec2(dir, 0.0)).rgb;
	ALBEDO = mix(g1, g2, blend);
}