extends Node
class_name GraphicsSettings

export(bool) var bloom := true setget set_bloom, get_bloom
export(bool) var high_quality_shadows := true setget set_hq_shadows, get_hq_shadows
export(bool) var disable_shadows := false setget set_shadow_disable
export(float, 0.1, 1.2, 0.1) var render_distance := 1.0 setget set_render_distance
export(bool) var render_distant_objects := true setget set_far_render
export(bool) var anti_aliasing := true setget set_anti_alias

func get_name():
	return "Graphics"

func set_bloom(b):
	bloom = b
	if is_inside_tree() and get_tree().current_scene.has_node("WorldEnvironment"):
		var we: WorldEnvironment = get_tree().current_scene.get_node("WorldEnvironment")
		we.environment.glow_enabled = bloom

func get_bloom():
	if is_inside_tree() and get_tree().current_scene.has_node("WorldEnvironment"):
		var we: WorldEnvironment = get_tree().current_scene.get_node("WorldEnvironment")
		return we.environment.glow_enabled
	else:
		return bloom

func set_hq_shadows(hq):
	high_quality_shadows = hq
	if high_quality_shadows: 
		ProjectSettings["rendering/quality/directional_shadow/size"] = 8192
		ProjectSettings["rendering/quality/shadow_atlas/size"] = 4096
		ProjectSettings["rendering/quality/shadows/filter_mode"] = 1
	else:
		ProjectSettings["rendering/quality/directional_shadow/size"] = 2048
		ProjectSettings["rendering/quality/shadow_atlas/size"] = 1024
		ProjectSettings["rendering/quality/shadows/filter_mode"] = 0
	if is_inside_tree() and get_tree().current_scene.has_node("DirectionalLight"):
		var d:DirectionalLight = get_tree().current_scene.get_node("DirectionalLight")
		if "high_quality" in d:
			d.high_quality = high_quality_shadows
	
func get_hq_shadows():
	return high_quality_shadows

func set_render_distance(d):
	render_distance = d
	if is_inside_tree():
		Global.render_distance = render_distance
		var cam := get_viewport().get_camera()
		if cam and "default_far_plane" in cam:
			cam.far = Global.render_distance*cam.default_far_plane
		if get_tree().current_scene.has_node("DirectionalLight"):
			var dl:DirectionalLight = get_tree().current_scene.get_node("DirectionalLight")
			if "high_quality" in dl:
				dl.distance = render_distance

func set_far_render(far):
	render_distant_objects = far
	Global.show_lowres = render_distant_objects

func set_shadow_disable(d):
	disable_shadows = d
	if get_tree().current_scene.has_method("get_sun"):
		var s = get_tree().current_scene.get_sun()
		if s:
			s.shadow_enabled = !disable_shadows

func set_anti_alias(a):
	anti_aliasing = a
	ProjectSettings["rendering/quality/filters/msaa"] = (2 if a else 0)
