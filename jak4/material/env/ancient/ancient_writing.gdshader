shader_type spatial;

uniform sampler2D writing_texture: hint_albedo;
uniform vec4 metal_color: hint_color;
uniform vec4 gem_color: hint_color;
uniform vec4 gem_emission: hint_color;
uniform float metal_specularity: hint_range(1, 32);
uniform float gem_specularity: hint_range(1, 32);
uniform float softness : hint_range(0.0, 1.0);

varying float specularity;
varying vec3 vert;

void vertex() {
	vert = VERTEX;
}

void fragment() {
	float factor = 0.0;
	float c = texture(writing_texture, UV).a;
	if(c > 0.14) {
		factor = 1.0;
	}
	vec4 color = mix(metal_color, gem_color, factor);
	specularity = mix(metal_specularity, gem_specularity, factor);
	
	ALBEDO = color.rgb;
	ROUGHNESS = (32.0 - specularity)/32.0;
	EMISSION = factor*gem_emission.rgb;
}

void light()
{
	// negative. Use as ambient shadow
	if(LIGHT_COLOR.r < 0.0 || LIGHT_COLOR.g < 0.0 || LIGHT_COLOR.b < 0.0) {
		DIFFUSE_LIGHT += (DIFFUSE_LIGHT + AMBIENT_LIGHT*ALBEDO)*LIGHT_COLOR*ATTENUATION;
	}
	else {
		float smoothness = 1.0 - ROUGHNESS;
		
		float ndotl = dot(NORMAL, LIGHT);
		float light = 0.4*(1.0-smoothness)*smoothstep(0, softness, ndotl);
		vec3 diffuse = light * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		// Specular
		vec3 h = normalize(VIEW + LIGHT);
		float cNdotH = max(0.0, dot(NORMAL, h));
		float blinn = 0.4*smoothness*pow(cNdotH, specularity);
		float intensity = blinn;
		vec3 specular = intensity * LIGHT_COLOR * ATTENUATION * ALBEDO;
		
		DIFFUSE_LIGHT += specular + diffuse;
	}
}
