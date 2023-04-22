extends Node

signal game_started
signal game_failed
signal game_completed

var active_game = null

func start(game: Object):
	if active_game:
		print_debug(
			"WARNING: tried to activate game [%s] while game [%s] was active"
			% [game.title, active_game.title])
		return

	active_game = game
	emit_signal("game_started", active_game.title, active_game.id)

func is_active():
	return active_game != null

func is_playing(game):
	return active_game and active_game == game

func end(success: bool):
	if success:
		add_stat(active_game, "completed")
		emit_signal("game_completed")
	else:
		add_stat(active_game, "failed")
		emit_signal("game_failed")
	active_game.end()
	active_game = null

func cancel_game():
	if is_active():
		end(false)

func set_spawn(spawn: Transform, teleport := true):
	if teleport:
		var p = Global.get_player()
		if p:
			p.teleport_to(spawn)
	Global.save_checkpoint(spawn)

func add_stat(game, sub_stat: String):
	var _x = Global.add_stat(get_stat(game, sub_stat))

func stat(game, sub_stat := ""):
	return Global.stat(get_stat(game, sub_stat))

func has_stat(game, sub_stat := ""):
	return Global.has_stat(get_stat(game, sub_stat))

func set_stat(game, sub_stat, value):
	Global.set_stat(get_stat(game, sub_stat), value)

func get_stat(game, sub_stat := "") -> String:
	if !game:
		print_stack()
		print_debug("No game!")
		return "_NO_GAME_"
	if sub_stat != "":
		sub_stat = "/" + sub_stat
	var game_name: String
	if game.friendly_id != "":
		game_name = game.friendly_id
	else:
		game_name = game.title + "." + str(game.id)
	return "games/" + game_name + sub_stat

func completed(game):
	return stat(game, "completed")
