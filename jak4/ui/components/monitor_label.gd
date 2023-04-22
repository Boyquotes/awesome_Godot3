extends Label

export(NodePath) var node
export(String) var property: String
export(String) var format := "%s"

var n:Node

func _ready():
	if !node:
		var split = property.split(".")
		node = NodePath(split[0])
		property = split[1]
		n = get_tree().current_scene.get_node(node)
	else:
		n = get_node(node)

func _process(_delta):
	if n:
		text = format % str(n.get(property))
