extends Spatial

export(Array, NodePath) var light_nodes

var ambient_info: Dictionary
var reflection_info: Dictionary

func _init():
	ambient_info = {}
	reflection_info = {}

func _ready():
	for l in light_nodes:
		var c = get_node(l)
		if c is ReflectionProbe and c.interior_enable:
			ambient_info[c.get_path()] = c.interior_ambient_color
			reflection_info[c.get_path()] = c.intensity

func toggle(lights_enabled, _instant := false):
	visible = lights_enabled
	for l in light_nodes:
		process_item(get_node(l), lights_enabled)

func process_item(c, lights_enabled):
	if c is Light:
		c.visible = lights_enabled
	elif c.get_path() in ambient_info:
		if lights_enabled:
			c.interior_ambient_color = ambient_info[c.get_path()]
			c.intensity = reflection_info[c.get_path()]
		else:
			c.interior_ambient_color = Color.black
			c.intensity = 0.01
