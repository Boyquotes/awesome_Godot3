extends Spatial

export(bool) var active = false setget set_active

func _ready():
	if !is_in_group("dynamic"):
		add_to_group("dynamic")
	set_active(active)

func _on_toggled(val: bool):
	set_active(val)

func set_active(a):
	active = a
	if !is_inside_tree():
		return
	if active:
		$AnimationPlayer.play("Loop")
		$AnimationPlayer.playback_speed = 1
	else:
		$AnimationPlayer.playback_speed = 0
