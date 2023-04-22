extends Spatial

export(Array, NodePath) var dead_enemies

func _ready():
	for n in dead_enemies:
		if !has_node(n):
			print_debug("WARNING: enemy doesn't exist: %s")
			continue
		var g = get_node(n)
		if g is EnemyBody and !g.is_dead():
			queue_free()
			return
