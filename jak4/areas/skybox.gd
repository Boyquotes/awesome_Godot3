extends MeshInstance

func _process(_delta):
	var c := get_viewport().get_camera()
	global_transform.origin = c.global_transform.origin
