shader_type spatial;
render_mode cull_disabled;

uniform sampler2D palette: hint_albedo;
uniform sampler2D gradient;
uniform sampler2D detail;
uniform float light_bias: hint_range(-1, 1);
uniform float softness: hint_range(0, 1) = 1.0;
uniform float specularity: hint_range(1, 16) = 1.0;

void fragment()
{
	float t = texture(palette, UV).r;
	float d = mix(1.0, texture(detail, UV*256.0).r, COLOR.b);
	ALBEDO = d*texture(gradient, vec2(t, 0)).rgb;
	ROUGHNESS = clamp(2.0/specularity, 0, 1);
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