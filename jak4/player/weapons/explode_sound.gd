extends AudioStreamPlayer3D

signal sound_finished(node)

func _ready():
	var _x = connect("finished", self, "_on_finished")

func _on_finished():
	emit_signal("sound_finished", self)
