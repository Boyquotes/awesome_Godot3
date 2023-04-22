extends Node

export(Array, String) var input_actions: Array

export(String) var text : String

func show():
	var player := Global.get_player()
	player.show_prompt(input_actions, text)
