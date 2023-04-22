shader_type spatial;

uniform sampler2D main_texture: hint_albedo;
uniform float subsurface_scattering: hint_range(-1, 1);
uniform float softness: hint_range(0, 1) = 1.0;
uniform float specularity: hint_range(0.1, 32) = 1.0;

varying vec3 vert_color;

void fragment()
{
	ALBEDO = texture(main_texture, UV).rgb;
	ROUGHNESS = (32.0 - specularity)/32.0;
	vert_color = COLOR.rgb;
}

void light()
{
	// negative. Use as ambient shadow
	if(LIGHT_COLOR.r < 0.0 || LIGHT_COLOR.g < 0.0 || LIGHT_COLOR.b < 0.0) {
		DIFFUSE_LIGHT += (DIFFUSE_LIGHT + AMBIENT_LIGHT*ALBEDO)*LIGHT_COLOR*ATTENUATION;
	}
	else {
		float smoothness = specularity/32.0;
		
		float ndotl = dot(NORMAL, LIGHT);
		float light = 0.4*(1.0-smoothness)*smoothstep(0, softness, ndotl);
		vec3 diffuse = light * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		// Specular
		vec3 h = normalize(VIEW + LIGHT);
		float cNdotH = max(0.0, dot(NORMAL, h));
		float blinn = 0.4*smoothness*pow(cNdotH, specularity);
		float intensity = blinn;
		vec3 specular = intensity * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		// subsurface
		vec3 subsurface = 0.2*ATTENUATION*LIGHT_COLOR*vert_color*clamp(ndotl + subsurface_scattering, 0, 1);
		
		DIFFUSE_LIGHT += specular + diffuse + subsurface;
	}
}
