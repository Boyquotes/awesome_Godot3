extends Area

export(int, 1, 100) var override_priority := 1
export(float, 0, 80) var wind_reduction_db := 10.0
export(Color) var custom_fog := Color.black
export(float, 0, 100) var fog_start := 10.0
export(float, 0, 2000) var fog_end := 200.0
export(Color) var indirect_light := Color.white
export(bool) var show_sun := true
export(bool) var override_music := false
export(AudioStream) var default_music
export(AudioStream) var combat_music
export(bool) var no_combat := false
export(bool) var close_cam := false

func _ready():
	var _x = connect("body_entered", self, "_on_body_entered", [], CONNECT_DEFERRED)
	_x = connect("body_exited", self, "_on_body_exited", [], CONNECT_DEFERRED)
	if get_overlapping_bodies().empty():
		hide()

func _on_body_entered(_body):
	var overrides := {
		"wind_reduction_db": wind_reduction_db
	}
	if custom_fog != Color.black:
		overrides["custom_fog"] = custom_fog
		overrides["fog_start"] = fog_start
		overrides["fog_end"] = fog_end
	if indirect_light != Color.white:
		overrides["indirect_light"] = indirect_light
	if override_music:
		overrides["default_music"] = default_music
		overrides["combat_music"] = combat_music
	overrides["show_sun"] = show_sun
	overrides["do_not_disturb"] = no_combat
	overrides["close_cam"] = close_cam
	overrides["id"] = hash(get_path())
	overrides["priority"] = override_priority
	get_tree().current_scene.apply_environment(overrides)
	show()

func _on_body_exited(_body):
	var id := hash(get_path())
	if is_inside_tree():
		get_tree().current_scene.remove_environment(id)
	hide()
