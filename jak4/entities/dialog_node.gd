extends Node
class_name DialogNode

signal dialog_entered

export(Resource) var dialog_sequence
export(String) var custom_entry := ""
export(NodePath) var main_speaker
export(String) var friendly_id
export(bool) var override := true

var speaker: Node = self

func _ready():
	if main_speaker:
		speaker = get_node(main_speaker)
		
func enter_dialog():
	var player = Global.get_player()
	if override or player.can_talk():
		player.start_dialog(self, dialog_sequence, speaker, custom_entry)
	emit_signal("dialog_entered")
