extends SpringArm

func get_hit_location():
	return global_transform.origin + global_transform.basis.z*get_hit_length()
