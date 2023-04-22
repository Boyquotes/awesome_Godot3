extends Spatial

signal activated
signal deactivated

signal toggled(active, instant)

export(bool) var active := false
export(bool) var used_by_player := true

func _ready():
	if Global.valid_game_state:
		if Global.has_stat(stat()):
			active = Global.stat(stat())
		else:
			Global.set_stat(stat(), active)
	if active:
		activate(true)
	else:
		deactivate(true)

func _on_Area_body_entered(_body):
	if active or !used_by_player:
		return
	if Global.remove_item("capacitor"):
		activate()

func activate(auto: bool = false):
	active = true
	$capacitor.show()
	if !auto:
		Global.set_stat(stat(), active)
	emit_signal("activated")
	emit_signal("toggled", active, auto)

func deactivate(auto := false):
	active = false
	$capacitor.hide()
	if !auto:
		Global.set_stat(stat(), active)
	emit_signal("deactivated")
	emit_signal("toggled", active, auto)

func stat():
	return str(get_path()) + "/activated"
