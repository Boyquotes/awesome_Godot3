extends Area

signal toggled(value)
signal locked

export(String) var key_item := ""

var active := false

func _ready():
	var _x = connect("body_entered", self, "_on_body_entered", [], CONNECT_DEFERRED)
	_x = connect("body_exited", self, "_on_body_exited", [], CONNECT_DEFERRED)

func _on_body_entered(body):
	if body is PlayerBody and !Global.count(key_item):
		emit_signal("locked")
		return
	if !active:
		emit_signal("toggled", true)
	active = true

func _on_body_exited(_body):
	var should_be_active = !get_overlapping_bodies().empty()
	if active and !should_be_active:
		emit_signal("toggled", false)
		active = false
