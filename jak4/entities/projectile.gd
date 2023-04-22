extends Area

export(int) var damage := 10
export(float) var speed := 10.0
export(float) var turn_speed := 2.0
export(Vector3) var offset := Vector3.ZERO

var source: Node
var target: Spatial

var velocity := Vector3.ZERO

const INACTIVE_TIME := 0.1
var active_time := 6.0

var timer := 0.0
var hitbox : Node
var disabled := false
var this_is_a_projectile := true

func _ready():
	if has_node("hitbox"):
		hitbox = $hitbox

func fire(p_target: Spatial, p_offset := Vector3.ZERO, p_time := 6.0):
	timer = 0.0
	active_time = p_time
	disabled = false
	var p = Global.get_player() as PlayerBody
	if !p.is_connected("died", self, "_on_player_died"):
		p.connect("died", self, "_on_player_died")
	offset = p_offset
	target = p_target
	if target:
		var direction = (
			target.global_transform.origin + offset
			 - global_transform.origin).normalized()
		velocity = speed*direction
	set_physics_process(true)

func _physics_process(delta):
	timer += delta
	if target:
		var dir = (
			target.global_transform.origin + offset
			 - global_transform.origin)
		var axis = velocity.cross(dir).normalized()
		if axis.is_normalized():
			var theta = velocity.angle_to(dir)
			var angle = sign(theta)*min(theta, turn_speed*delta)
			velocity = velocity.rotated(axis, angle)
		
	global_translate(velocity*delta)
	if timer > active_time:
		_remove()

func take_damage(_damage, _dir, _source: Node, _tag := ""):
	_remove()

func gravity_stun(_damage):
	velocity *= 0.25
	velocity.y += 3.0
	turn_speed *= 0.25

func dir_damage(body):
	if !body.has_method("take_damage"):
		return
	var dir :Vector3 = velocity.normalized()
	body.take_damage(damage, dir, source, "projectile")

func _on_deletion_timer_timeout():
	_remove()

func _on_projectile_body_entered(body):
	if body == hitbox or "this_is_a_projectile" in body:
		return
	if timer > INACTIVE_TIME:
		dir_damage(body)
		_remove()

func _on_player_died():
	_remove()

func _remove():
	if disabled:
		return
	disabled = true
	set_physics_process(false)
	ObjectPool.call_deferred("put", "orb", self)
