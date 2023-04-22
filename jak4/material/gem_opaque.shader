shader_type spatial;

uniform sampler2D main_texture: hint_albedo;
uniform float light_bias : hint_range(-1.0, 1.0, 0.1);
uniform float softness: hint_range(0, 1) = 1.0;
uniform float specularity: hint_range(1, 32) = 1.0;
uniform vec4 subsurface: hint_color = vec4(0.0);
uniform float emission: hint_range(0, 3) = 0.0;

void fragment()
{
	ALBEDO = texture(main_texture, UV).rgb;
	ROUGHNESS = (32.0 - specularity)/32.0;
	EMISSION = (subsurface*emission).rgb;
}

void light()
{
	// negative. Use as ambient shadow
	if(LIGHT_COLOR.r < 0.0 || LIGHT_COLOR.g < 0.0 || LIGHT_COLOR.b < 0.0) {
		DIFFUSE_LIGHT += (DIFFUSE_LIGHT + AMBIENT_LIGHT*ALBEDO)*LIGHT_COLOR*ATTENUATION;
	}
	else {
		float smoothness = (specularity + 2.0) / (8.0*3.1416);
		
		float ndotl = dot(NORMAL, LIGHT) + light_bias;
		float light = 0.4*smoothstep(0, softness, ndotl);
		vec3 diffuse = light * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		// Specular
		vec3 h = normalize(VIEW + LIGHT);
		float cNdotH = max(0.0, dot(NORMAL, h));
		float blinn = 0.4*smoothness*pow(cNdotH, specularity);
		float intensity = blinn;
		vec3 specular = intensity * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		// subsurface
		vec3 s = 0.2*ATTENUATION*LIGHT_COLOR*subsurface.rgb*subsurface.a;
		
		DIFFUSE_LIGHT += specular + diffuse + s;
	}
}
