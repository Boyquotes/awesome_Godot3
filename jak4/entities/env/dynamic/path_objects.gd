extends Path

export(float, 0, 1) var unit_speed := 0.1

func _physics_process(delta):
	for c in get_children():
		if c is PathFollow:
			c.unit_offset += unit_speed*delta
			if c.unit_offset > 1:
				c.unit_offset -= 1
