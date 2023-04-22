extends Control

func _ready():
	set_process_input(false)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		set_process_input(false)
		$AnimationPlayer.play("fade_out")

func accept_input():
	set_process_input(true)

func resume_game():
	get_tree().change_scene("res://areas/world.tscn")
