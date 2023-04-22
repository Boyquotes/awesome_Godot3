extends Camera

export(float) var default_far_plane := 14000.0
onready var spring := $"../SpringArm"

func _process(_delta):
	global_transform.origin = spring.get_hit_location()
