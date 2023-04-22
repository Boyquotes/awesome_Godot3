extends Spatial

export(NodePath) var water := NodePath("circle")

func _ready():
	if has_node(water):
		var w = get_node(water)
		var water_up: Vector3 = w.global_transform.basis.y
		var axis := water_up.cross(Vector3.UP).normalized()
		if axis.is_normalized():
			var angle := water_up.angle_to(Vector3.UP)
			w.global_rotate(axis, angle)
