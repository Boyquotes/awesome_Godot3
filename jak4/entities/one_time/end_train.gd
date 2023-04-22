extends Spatial

func _ready():
	if !Global.stat("mum/end"):
		queue_free()

func end_game():
	$AnimationPlayer.play("end_game")
	Global.get_player().disable()
	get_tree().paused = true

func go_to_credits():
	var _x = get_tree().change_scene("res://ui/credits_screen.tscn")
