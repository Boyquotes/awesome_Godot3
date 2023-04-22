extends Node

func _on_activated():
	print("Collapsing bridge")
	for c in get_children():
		if c is RigidBody:
			c.mode = RigidBody.MODE_RIGID
			c.apply_central_impulse(Vector3.DOWN*0.1)
