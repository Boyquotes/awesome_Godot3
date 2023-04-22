extends NPC_Shop

export(bool) var only_if_saved := true
export(bool) var delete_if_saved := true
export(Array, NodePath) var enemies : Array

var saved := false

class RileyGame:
	const title := "Enemies"
	const friendly_id := ""
	var id: int
	
	func _init(p_id: int):
		id = p_id
	
	func end():
		pass

onready var game = RileyGame.new(hash(get_path()))

func _init():
	enemies = []
	visual_name = "Riley"

func _ready():
	if only_if_saved and !Global.stat("riley/saved"):
		queue_free()
	elif Global.stat(str(get_path()) + "/saved"):
		saved = true
		if delete_if_saved:
			queue_free()
	for i in range(enemies.size()):
		# convert from node-relative to absolute position
		var n = get_node(enemies[i])
		enemies[i] = n.get_path()
	for e in enemies:
		var _x = get_node(e).connect("died", self, "_on_target_died", [], CONNECT_ONESHOT)

func _on_target_died(_id, path):
	var idx = enemies.find(path)
	if idx < 0:
		print_debug("Enemy was not in list! ", path)
		return

	var p = Global.get_player()
	if enemies.size() <= 1:
		complete_game()
	elif CustomGames.is_playing(game):
		p.game_ui.value = enemies.size() - 1
		p.game_ui.remove_target(get_node(enemies[idx]))
	enemies.remove(idx)

func complete_game():
	var _x = Global.add_stat("riley/saved")
	_x = Global.add_stat(str(get_path()) + "/saved")
	saved = true
	if CustomGames.is_playing(game):
		CustomGames.end(true)

func track_enemies():
	if enemies.size() == 0:
		complete_game()
		return
	var player = Global.get_player()
	CustomGames.start(game)
	CustomGames.set_spawn(player.get_save_transform(), false)
	
	player.game_ui.value = enemies.size()
	for e in enemies:
		player.game_ui.add_target(get_node(e))
