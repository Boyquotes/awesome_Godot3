extends Spatial

export(bool) var enable_light := true
export(NodePath) var light

func _ready():
	if has_node(light):
		get_node(light).visible = enable_light
