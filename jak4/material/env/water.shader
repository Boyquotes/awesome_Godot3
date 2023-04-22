shader_type spatial;
render_mode world_vertex_coords, cull_back;

uniform vec4 surface_albedo : hint_color;
uniform vec4 deep_albedo : hint_color;
uniform float max_depth : hint_range(0.1, 100.0) = 1.0;
uniform vec4 foam_color : hint_color;
uniform float refraction : hint_range(-1,1) = 0.004;
uniform float foam_distance : hint_range(0, 5) = 0.5;
uniform sampler2D foam_noise;
uniform float foam_noise_scale : hint_range(0.1, 4) = 1.0;
uniform float foam_noise_scale2 : hint_range(0.1, 2) = 0.2;
varying vec3 pos;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec3 ref_normal = NORMAL;
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
	float ref_amount = 1.0;

	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	vec4 wpos = CAMERA_MATRIX*upos;
	vec3 pixel_position = wpos.xyz / wpos.w;
	
	float diffy = pos.y - pixel_position.y;
	vec2 foam_sample_offset = 0.5*vec2(sin(TIME*0.05 + 0.2+pos.x + 0.1*pos.z), cos(TIME*0.02 + 0.16*pos.x));
	float foam_factor = texture(foam_noise, pos.xz*foam_noise_scale + foam_sample_offset).r;
	foam_factor *= texture(foam_noise, pos.xz*foam_noise_scale2).r;
	
	float f = foam_color.a * float(diffy >= -0.1 && diffy < foam_distance*foam_factor);
	
	vec4 color = textureLod(SCREEN_TEXTURE, ref_ofs, 0);
	float amount = pow(clamp(diffy/max_depth, 0.0, 1.0), 0.2);
	
	EMISSION = mix(color.rgb * mix(surface_albedo, deep_albedo, amount).rgb, vec3(0.0), f);
	
	ALBEDO = mix(vec3(0), foam_color.rgb, f);
	ROUGHNESS = mix(0.0, 0.3, f);
	METALLIC = 0.8;
	SPECULAR = 1.0;
}

void light()
{
	// negative. Use as ambient shadow
	if(LIGHT_COLOR.r < 0.0 || LIGHT_COLOR.g < 0.0 || LIGHT_COLOR.b < 0.0) {
		DIFFUSE_LIGHT += (DIFFUSE_LIGHT + AMBIENT_LIGHT*ALBEDO)*LIGHT_COLOR*ATTENUATION;
	}
	else {
		float light = dot(NORMAL, LIGHT);
		DIFFUSE_LIGHT += light * ATTENUATION * ALBEDO;
		
		// Specular
		vec3 h = normalize(VIEW + LIGHT);
		float cNdotH = max(0.0, dot(NORMAL, h));
		float blinn = pow(cNdotH, (1.0/(ROUGHNESS + 0.01)));
		DIFFUSE_LIGHT += LIGHT_COLOR * blinn * ATTENUATION * ALBEDO;
	}
}
