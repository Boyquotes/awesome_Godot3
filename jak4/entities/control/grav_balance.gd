extends KinematicBody

export(float) var max_rotation_degrees := 11.0
export(float) var degrees_per_second := 30.0

var rot_speed := 0.0
var mass_one := 0.0
var mass_two := 0.0
onready var original_angle:Vector3 = rotation_degrees

func _ready():
	set_physics_process(false)

func activate():
	set_physics_process(true)

func _physics_process(delta):
	var desired_angle: float = original_angle.z + clamp(mass_one - mass_two,
	-max_rotation_degrees,
	max_rotation_degrees)
	var angle = desired_angle - rotation_degrees.z
	rotation_degrees.z += clamp(angle, -degrees_per_second*delta, degrees_per_second*delta)
	if angle < 0.01:
		set_physics_process(false)
