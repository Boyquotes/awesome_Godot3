extends RigidBody

export(float, 0, 10) var delay := 1.0

const time_to_unlock := 1.0

var falling := false
onready var starting_position := global_transform

func _ready():
	var p = Global.get_player()
	if p is PlayerBody:
		p.connect("died", self, "_on_player_died")

func _on_body_entered(body):
	if body is PlayerBody and body.velocity.y > 1.0 && body.global_transform.origin.y < global_transform.origin.y:
		return
	can_sleep = false
	if !falling:
		falling = true
		$Timer.start(delay)

func _on_timeout():
	sleeping = false
	mode = RigidBody.MODE_RIGID

func _on_player_died():
	reset()

func reset():
	can_sleep = true
	$Timer.stop()
	mode = RigidBody.MODE_KINEMATIC
	global_transform = starting_position
	falling = false

#TODO: for resetting by button. Make a nice visual effect to teleport them
func visual_reset():
	reset()
