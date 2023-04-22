shader_type spatial;
render_mode async_hidden,blend_mix,depth_draw_never,cull_back;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float subsurface_scattering: hint_range(-1.0, 1.0, 0.1) = 1.0;

void vertex() {
	mat4 mat_world = mat4(
		normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),
		normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),
		normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),
		WORLD_MATRIX[3]);
	mat_world = mat_world * mat4(
		vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = COLOR.rgb * albedo_tex.rgb;
	ALPHA = COLOR.a * albedo_tex.a;
}

void light()
{
	// negative. Use as ambient shadow
	if(LIGHT_COLOR.r < 0.0 || LIGHT_COLOR.g < 0.0 || LIGHT_COLOR.b < 0.0) {
		DIFFUSE_LIGHT += (DIFFUSE_LIGHT + AMBIENT_LIGHT*ALBEDO)*LIGHT_COLOR*ATTENUATION;
	}
	else {
		DIFFUSE_LIGHT += 0.3 * LIGHT_COLOR * ATTENUATION * ALBEDO;
	}
}
