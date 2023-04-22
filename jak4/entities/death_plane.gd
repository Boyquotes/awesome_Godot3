extends MeshInstance

func _on_body_entered(body):
	if body is PlayerBody:
		body.fall_to_death()
