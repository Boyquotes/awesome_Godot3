extends KinematicBody

signal toggled(on, instant)

export(String) var key := "" 
export(bool) var player_only := false
export(bool) var persistent := true

func _ready():
	if persistent and Global.stat(get_path()):
		emit_signal("toggled", true, true)

func take_damage(_d, _dir, source, _tag := ""):
	if player_only and !(source is PlayerBody):
		print("Not player: ", source)
		return
	elif !Global.count(key):
		print("No key: ", key)
		return
	else:
		if persistent:
			Global.set_stat(get_path(), true)
		print("Opening..")
		emit_signal("toggled", true, false)
