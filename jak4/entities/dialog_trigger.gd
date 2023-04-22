extends Area
class_name DialogTrigger

export(Resource) var dialog_sequence
export(String) var custom_entry := ""
export(NodePath) var main_speaker
export(String) var friendly_id
export(bool) var enabled := true setget set_enabled

var speaker: Node

func _ready():
	var _x = connect("body_entered", self, "_on_body_entered")
	if main_speaker:
		speaker = get_node(main_speaker)
	set_enabled(enabled)

func _on_body_entered(body):
	if !(body is PlayerBody):
		print_debug("BUG: Non-player triggered dialog node ", get_path())
		return
	if body.can_talk():
		body.start_dialog(self, dialog_sequence, speaker, custom_entry)

func set_enabled(e):
	enabled = e
	for c in get_children():
		if c is CollisionShape:
			c.disabled = !enabled
		elif c is DialogCircle:
			c.enabled = enabled

func deactivate():
	set_enabled(false)

func activate():
	set_enabled(true)
