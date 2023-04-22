shader_type spatial;
render_mode depth_draw_alpha_prepass, cull_disabled;

uniform sampler2D main_texture: hint_albedo;
uniform float subsurface_scattering: hint_range(-1, 1);
uniform float softness: hint_range(0, 1) = 1.0;
uniform float specularity: hint_range(0.0, 32) = 1.0;
uniform float alpha_clip: hint_range(0.001, 1.0) = 0.75;

varying vec3 vert_color;
varying vec3 ground_color;
varying float vert_pos;

void vertex() {
	ground_color = pow(INSTANCE_CUSTOM.rgb, vec3(2.2));
	vert_pos = VERTEX.y;
}

void fragment()
{
	float interp = clamp(2.0*(vert_pos), 0.0, 1.0);
	vec4 tex = texture(main_texture, UV);
	if(tex.a < alpha_clip){
		discard;
	}
	else {
		ALBEDO = mix(ground_color, tex.rgb, interp);
		ROUGHNESS = 1.0;
		vert_color = mix(vec3(0.0), COLOR.rgb, interp);
	}
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
