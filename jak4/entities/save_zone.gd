extends Area

export(bool) var heal := true

func _ready():
	var _x = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body is PlayerBody and body.can_save():
		if heal:
			body.call_deferred("heal")
		Global.call_deferred("save_checkpoint", body.get_save_transform())
