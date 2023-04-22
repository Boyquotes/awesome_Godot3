extends SpringArm

export(NodePath) var laser_geometry = NodePath("../laser_geometry")
onready var lgeo: MeshInstance = get_node(laser_geometry)

func update():
	var l = get_hit_length()
	if l < spring_length:
		for c in get_children():
			c.show()
	else:
		for c in get_children():
			c.hide()
	if l == INF:
		l = 100
	lgeo.transform.basis.z = Vector3(0, 0, l)
