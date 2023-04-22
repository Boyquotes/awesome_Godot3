extends Spatial

var removed_children:Dictionary

func _init():
	removed_children = {}

func _ready():
	for c in get_children():
		removed_children[c] = c.global_transform
		remove_child(c)

func spawn():
	for c in removed_children.keys():
		add_child(c)
		c.global_transform = removed_children[c]
	removed_children.clear()
