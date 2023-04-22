shader_type spatial;

uniform vec4 albedo : hint_color;
uniform float refraction : hint_range(-5,5);
uniform float brightness : hint_range(0, 2);
uniform float speed : hint_range(-20, 20);
uniform float vertex_deform: hint_range(0, 4);
uniform sampler2D normal_map : hint_normal;

void vertex() {
	float deform = sin(3.14*UV.y + 6.0*VERTEX.x+4.0*VERTEX.z + TIME*speed)*vertex_deform;
	VERTEX += NORMAL*deform;
	UV.y += TIME*speed;
}

void fragment() {
	ALBEDO = albedo.rgb;
	SPECULAR = 1.0;
	METALLIC = 1.0;
	ROUGHNESS = 0.0;
	NORMALMAP = texture(normal_map, UV).rgb;
	vec3 ref_normal = normalize(NORMAL + NORMALMAP);
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
	float ref_amount = 1.0;
	EMISSION = textureLod(SCREEN_TEXTURE, ref_ofs, 0).rgb * ALBEDO;
	TRANSMISSION = EMISSION;
	ALBEDO *= brightness;
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