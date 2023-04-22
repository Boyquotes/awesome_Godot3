extends Area

export(Vector3) var direction := Vector3.ZERO
export(Vector3) var relative_direciton_factor := Vector3(1,1,1)
export(int) var damage := 10
export(bool) var active := false
export(bool) var time_sensitive := false

func _ready():
	var _x = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if !active:
		return
	if !body.has_method("take_damage"):
		return
	if time_sensitive and body is PlayerBody and TimeManagement.time_slowed:
		return
	var dir := direction
	if dir == Vector3.ZERO:
		dir = (relative_direciton_factor*(body.global_transform.origin - global_transform.origin).normalized())
	body.take_damage(damage, dir, self)
