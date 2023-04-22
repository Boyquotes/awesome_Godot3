extends TextureRect

export(Texture) var gamepad_prompt
export(Texture) var keyboard_prompt

func _enter_tree():
	var _x = connect("visibility_changed", self, "_on_visibility_changed")

func _on_visibility_changed():
	if visible:
		if Global.using_gamepad:
			texture = gamepad_prompt
		else:
			texture = keyboard_prompt
