shader_type spatial;
render_mode cull_back, depth_draw_opaque, async_hidden;


uniform sampler2D wall: hint_albedo;
uniform sampler2D ground: hint_albedo;
uniform sampler2D ceiling: hint_albedo;
uniform float uv_scale = 0.125;
uniform float power = 5.0;
uniform float softness = 0.5;
uniform float specularity: hint_range(1.0, 32.0) = 1.0;
uniform float subsurface_scattering: hint_range(-1, 1) = -1.0;

varying vec3 position;
varying vec3 normal;
varying vec3 vert_color;

void vertex() {
	position = VERTEX.xyz;
	normal = NORMAL;
	vert_color = COLOR.rgb;
}

void fragment() {
	vec4 color_x = texture(wall, position.zy*uv_scale);
	vec4 color_z = texture(wall, position.xy*uv_scale);
	vec4 color_y_up = texture(ground, position.xz*uv_scale);
	vec4 color_y_down = texture(ceiling, position.xz*uv_scale);
	
	float y_pow = sign(normal.y)*pow(abs(normal.y), power);
	
	vec4 color =
		color_x*pow(normal.x, 2) 
		+ color_z*pow(normal.z, 2)
		+ color_y_up*max(y_pow, 0.0)
		+ color_y_down*max(-y_pow, 0.0);
	ALBEDO = clamp(color.rgb, vec3(0.0), vec3(1.0));
	ROUGHNESS = (32.0 - specularity)/32.0;
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
