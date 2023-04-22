extends Spatial
export(PackedScene) var ui: PackedScene

func _on_entrance_body_entered(body):
	if body is PlayerBody and body.can_talk():
		body.ui.open_custom(ui)
