extends KinematicBody
class_name GravityPlatform

export(float) var initial_velocity = 10.0
export(float) var damage_speed := 0.1
export(float) var damage_on_hit := 10.0
export(bool) var elevator := false
export(Vector3) var max_rotation_speed := Vector3(0.3, 0.3, 0.3)

enum State {
	Inactive,
	GravityStunned,
	Falling,
	Planting
}

var state = State.Inactive
var grav_time := 0.0
var velocity := 0.0
var axis := Vector3.ZERO
var rotate_speed := 0.0
onready var original_y = global_transform.origin.y
var damaged_bodies = []

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	match state:
		State.GravityStunned:
			velocity *= clamp(1.0 - delta, 0.1, 0.995)
			velocity += delta*Global.gravity_stun_velocity
			var old_origin := global_transform.origin
			var desired_movement:Vector3 = Vector3.UP*velocity*delta
			
			var col = move_and_collide(desired_movement)
			var real_movement := global_transform.origin - old_origin
			
			if col and !elevator and !col.collider.is_in_group("push_always"):
				velocity *= 0.9
			if col and col.collider.is_in_group("push"):
				global_translate(desired_movement - real_movement)
			if rotate_speed != 0:
				global_rotate(axis, delta*rotate_speed)
			grav_time += delta
			if grav_time > Global.gravity_stun_time:
				state = State.Falling
		State.Falling:
			velocity -= 9.8*delta
			global_translate(Vector3.UP*velocity*delta)
			if global_transform.origin.y < original_y:
				if is_in_group("dynamic"):
					remove_from_group("dynamic")
				set_physics_process(false)
				velocity = 0
	
func gravity_stun(_damage):
	if !is_in_group("dynamic"):
		add_to_group("dynamic")
	var angular_speed: Vector3 = max_rotation_speed*Vector3(randf(),randf(),randf())
	axis = angular_speed.normalized()
	rotate_speed = angular_speed.length()
	damaged_bodies = []
	state = State.GravityStunned
	grav_time = 0.0
	set_physics_process(true)
	velocity = initial_velocity

func take_damage(_damage, _dir, _source: Node, _tag := ""):
	pass
	#velocity += damage*damage_speed

func _on_damage_area_body_entered(body):
	if state != State.Falling or body in damaged_bodies or !body.has_method("take_damage"):
		return
	#var dir = (body.global_transform.origin - global_transform.origin).normalized()
	#body.take_damage(damage_on_hit, dir, self)
	#take_damage(1, -dir, self)

