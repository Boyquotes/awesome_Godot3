extends Area

export(float) var velocity := 2.0
export(bool) var active := true setget set_active
const FORCE_ON_BODIES := 4.0

func _ready():
	set_physics_process(false)
	var _x = connect("body_entered", self, "_check")
	_x = connect("body_exited", self, "_check")

func _check(_b = null):
	set_physics_process(active and !get_overlapping_bodies().empty())

func set_active(a):
	active = a
	_check()

func _physics_process(_delta):
	var dir = global_transform.basis.y
	for b in get_overlapping_bodies():
		if b is PlayerBody:
			if TimeManagement.time_slowed:
				continue
			if b.velocity.dot(dir) > velocity:
				continue
			b.velocity = (
				b.velocity.slide(global_transform.basis.y)
				+ global_transform.basis.y*velocity)
		elif b is RigidBody:
			var vdot = velocity - b.linear_velocity.dot(dir)
			var acceleration = max(vdot, 0)*vdot*dir
			b.add_central_force(FORCE_ON_BODIES*b.mass*acceleration)
