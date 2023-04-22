extends Spatial

signal cleared

var enemies: Dictionary

func _init():
	enemies = {}

func _ready():
	for e in get_children():
		if e is EnemyBody and !e.is_dead():
			enemies[e.get_path()] = e
			var _x = e.connect("died", self, "_on_enemy_died", [])
	if enemies.empty():
		print("No enemies.")
		mark_cleared()

func mark_cleared():
	emit_signal("cleared")

func _on_enemy_died(_id, _path):
	print("Enemies killed")
	for e in enemies.values():
		if !e.is_dead():
			return
	mark_cleared()
