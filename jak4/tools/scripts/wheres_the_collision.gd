tool
extends EditorScript

func _run():
	search(get_scene())

func search(node):
	if node is CollisionObject and !(node is EnemyBody) and node.collision_layer & 6:
		print("Naughty: ", node.get_path())
	else:
		for c in node.get_children():
			search(c)
