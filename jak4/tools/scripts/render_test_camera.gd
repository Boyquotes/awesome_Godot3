extends Camera

func _process(delta):
	global_transform = global_transform.looking_at(Vector3.ZERO, Vector3.UP)
