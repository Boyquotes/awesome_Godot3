tool
extends Chunk

export(String) var safe_stat := "112_safe"
var tracked_stats := ["hdw_gate"]

func _ready():
	var _x = Global.connect("stat_changed", self, "_on_stat_changed")

func _on_stat_changed(stat, _value):
	if stat in tracked_stats:
		var safe_gate = Global.stat("hdw_gate")
		Global.set_stat(safe_stat, safe_gate)
