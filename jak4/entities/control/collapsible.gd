extends KinematicBody

export(float) var damage_force := 0.1
export(Vector3) var falling_rotation := Vector3.ZERO

var falling := false
var velocity := Vector3.ZERO
var angular_velocity := Vector3.ZERO
onready var initial_transform = transform

func _ready():
	if !is_in_group("dynamic"):
		add_to_group("dynamic")
	var _x = Global.get_player().connect("died", self, "reset")
	set_physics_process(false)

func _physics_process(delta):
	if !falling:
		set_physics_process(false)
		return
	
	velocity += delta*Vector3.DOWN*9.8
	global_rotate(falling_rotation.normalized(), delta*falling_rotation.length())
	var col := move_and_collide(velocity*delta, false)
	if col and col.collider:
		if !col.collider.is_in_group("push") and col.normal.y > 0.78:
			velocity = Vector3.ZERO
			falling = false
		else:
			velocity = velocity.slide(col.normal)

func take_damage(damage, dir, _source: Node, tag := ""):
	if tag == "spin":
		return
	falling = true
	set_physics_process(true)
	velocity = damage*dir*damage_force

func reset():
	falling = false
	set_physics_process(false)
	transform = initial_transform
	velocity = Vector3.ZERO
