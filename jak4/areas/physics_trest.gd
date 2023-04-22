extends Spatial

func _input(event):
	if event.is_action_pressed("choose_item"):
		$AnimationPlayer.play("Fall")
