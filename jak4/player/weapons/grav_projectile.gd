extends RigidBody

signal contact(node)

var speed := 20.0
var explode_on_contact := false
var flight_time := 0.0
const MIN_TIME := 0.25

func fire(direction: Vector3):
	$bounce_sound.stop()
	explode_on_contact = false
	flight_time = 0.0
	angular_velocity = Vector3.ZERO
	linear_velocity = speed*direction
	set_physics_process(true)

func _physics_process(delta):
	flight_time += delta
	if !Input.is_action_pressed("combat_shoot"):
		if flight_time < MIN_TIME:
			explode_on_contact = true
			set_physics_process(false)
		elif !explode_on_contact:
			emit_signal("contact", self)
			return

func _on_body_entered(_body):
	if explode_on_contact:
		emit_signal("contact", self)
	else:
		$bounce_sound.play()
