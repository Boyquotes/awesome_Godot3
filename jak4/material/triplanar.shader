shader_type spatial;
render_mode cull_back, depth_draw_opaque, world_vertex_coords, async_hidden;

uniform sampler2D wall: hint_albedo;
uniform sampler2D ground: hint_albedo;
uniform sampler2D ceiling: hint_albedo;
uniform float wall_scale = 0.125;
uniform float ground_scale = 0.125;
uniform float power = 5.0;
uniform float softness = 0.5;
uniform float specularity_ground: hint_range(1, 32) = 1.0;
uniform float specularity_wall: hint_range(1, 32) = 1.0;
uniform float specularity_ceiling: hint_range(1, 32) = 1.0;
uniform float light_bias: hint_range(-1.0, 1.0) = 0.0;
uniform float shadow_normal_offset : hint_range(-5.0, 5.0, 0.1) = 0.2;

varying vec3 position;
varying vec3 normal;
varying float specularity;

void vertex() {
	position = VERTEX.xyz;
	normal = NORMAL;
}

void fragment() {
	SHADOW_NORMAL_OFFSET = shadow_normal_offset;
	vec3 n = normalize(normal);
	vec4 color_x = texture(wall, position.zy*wall_scale);
	vec4 color_z = texture(wall, position.xy*wall_scale);
	vec4 color_y_up = texture(ground, position.xz*ground_scale);
	vec4 color_y_down = texture(ceiling, position.xz*ground_scale);
	
	float y_pow = sign(n.y)*pow(abs(n.y), power);
	
	vec4 color =
		color_x*pow(n.x, 2) 
		+ color_z*pow(n.z, 2)
		+ color_y_up*max(y_pow, 0.0)
		+ color_y_down*max(-y_pow, 0.0);
	specularity = 
		specularity_wall*(abs(n.z) + abs(n.x))
		+ specularity_ground*max(y_pow, 0.0)
		+ specularity_ceiling*max(-y_pow, 0.0);
	ALBEDO = clamp(color.rgb, vec3(0.0), vec3(1.0));
	//ROUGHNESS = clamp(2.0/(specularity + 0.01), 0, 1);
}

void light()
{
	// negative. Use as ambient shadow
	if(LIGHT_COLOR.r < 0.0 || LIGHT_COLOR.g < 0.0 || LIGHT_COLOR.b < 0.0) {
		DIFFUSE_LIGHT += (DIFFUSE_LIGHT + AMBIENT_LIGHT*ALBEDO)*LIGHT_COLOR*ATTENUATION;
	}
	else {
		float spec = specularity/32.0;
		float light = smoothstep(0, softness, dot(NORMAL, LIGHT) + light_bias);
		DIFFUSE_LIGHT += 0.4*(1.0-spec) * light * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		// Specular
		vec3 h = normalize(VIEW + LIGHT);
		float cNdotH = max(0.0, dot(NORMAL, h));
		float blinn = pow(cNdotH, specularity);
		blinn *= spec;
		float intensity = blinn; 
		DIFFUSE_LIGHT += LIGHT_COLOR * intensity * ATTENUATION * ALBEDO;
	}
}
