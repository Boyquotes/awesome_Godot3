extends Spatial

signal game_completed
signal game_failed

export(int) var max_jumps := 1
export(int) var bugs_earned := 2
export(int) var gems_earned := 4
export(String) var friendly_id := ""

const title = "Jumps"
onready var id := hash(get_path())

var jumps := 0
# TODO: Sound effect and confetti particles
onready var game_target := $game_target
onready var game_start := $game_start

func _ready():
	game_target.hide()

func start():
	if CustomGames.is_active():
		return

	CustomGames.start(self)
	CustomGames.set_spawn(game_start.global_transform)
	
	game_target.show()
	jumps = 0
	
	var player = Global.get_player()
	player.game_ui.add_target(game_target)
	player.game_ui.value = max_jumps
	
	var _x = player.connect(
		"jumped",self, "_on_player_jumped",
		[], CONNECT_DEFERRED)
	_x = game_target.connect(
		"body_entered", self, "_on_target_entered",
		[], CONNECT_ONESHOT | CONNECT_DEFERRED)

func end():
	game_target.hide()
	if game_target.is_connected("body_entered", self, "_on_target_entered"):
		game_target.disconnect("body_entered", self, "_on_target_entered")
	var pl = Global.get_player()
	pl.disconnect("jumped", self, "_on_player_jumped")
	pl.celebrate()

func _on_player_jumped() :
	var player = Global.get_player()
	jumps += 1
	if jumps > max_jumps:
		CustomGames.end(false)
	else:
		player.game_ui.value = max_jumps - jumps

func _on_target_entered(_body):
	if CustomGames.is_playing(self):
		if !completed():
			var _x = Global.add_item("bug", bugs_earned)
		else:
			var _x = Global.add_item("gem", gems_earned)
		CustomGames.end(true)

func completed():
	return CustomGames.completed(self)
