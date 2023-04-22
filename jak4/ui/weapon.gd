extends TextureRect

export(String) var icon setget set_icon

func set_icon(i: String):
	icon = i
	texture = load("res://ui/icons/wep_%s.svg" % icon)
