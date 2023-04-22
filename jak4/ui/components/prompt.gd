extends TextureRect

export(Texture) var gamepad_texture
export(Texture) var keyboard_texture

func _ready():
	check_prompts()
	var _x = connect("visibility_changed", self, "_on_visibility_changed")

func _on_visibility_changed():
	if visible:
		check_prompts()

func check_prompts():
	if Global.using_gamepad:
		texture = gamepad_texture
	else:
		texture = keyboard_texture
