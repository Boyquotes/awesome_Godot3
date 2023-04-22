extends Spatial

onready var sun = $"../../sun"

func _process(_delta):
	var c := get_viewport().get_camera()
	scale = Vector3(c.far, c.far, c.far)
	global_transform.origin = c.global_transform.origin
	$skybox_sun.get_surface_material(0).set_shader_param("color", sun.light_color)
