extends ProgressBar

export(NodePath) var node
export(String) var property

onready var n := get_node(node)

func _process(_delta):
	var val:float = n.get(property)
	if val > max_value:
		max_value = val
	value = val
