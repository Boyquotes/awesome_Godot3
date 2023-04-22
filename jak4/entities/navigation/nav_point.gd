extends Spatial
class_name NavPoint

signal entered

enum Action {
	None,
	Jump,
	Look,
	OpenDoor
}

export(NodePath) var next
export(Action) var action = Action.None
export(String) var chunk_entry

func mark_entered():
	emit_signal("entered")
