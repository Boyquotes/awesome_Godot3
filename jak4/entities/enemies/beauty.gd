extends KinematicBody

signal died(id, path)

enum AIState {
	Inactive,
	# When to use Stalk versus Chase?
	Stalk,
	Chase,
	MoveWindup,
	MoveActive,
	MoveEnd,
	Dead
}

enum MoveState {
	Locked,
	Ground,
	JumpCharge,
	Jumping,
	# Is this needed?
	Air,
	GravityStun
}

# Assumed true for now
export(AIState) var ai_state = AIState.Inactive
export(int) var health := 250
export(bool) var reset_on_player_death := false
export(bool) var cloaked := false
export(NodePath) var navigation
export(float) var chase_speed := 7.0
export(bool) var lock_damage_override := false
export(String) var activation_stat := ""
var move_state = MoveState.Locked

onready var nav := $NavigationAgent
onready var debug_path := $Node/ImmediateGeometry
onready var body:Spatial = $body
onready var animTree :AnimationTree = $AnimationTree
onready var move_anim :AnimationNodeStateMachinePlayback = animTree["parameters/Movement/playback"]

var player: PlayerBody
var player_last_origin := Vector3.ZERO

onready var hitboxes := [
	$body/hitboxes/dash_hitbox,
	$body/Armature/Skeleton/forearm_l/hitbox,
	$body/Armature/Skeleton/forearm_r/hitbox
]

const GRAVITY := Vector3.DOWN*24.0
var velocity := Vector3.ZERO
const ACCEL_GROUND := 20.0
var orb := load("res://entities/projectile.tscn")
var damaged_objects : Array

onready var guns := [
	$body/Armature/Skeleton/forearm_l/gun,
	$body/Armature/Skeleton/forearm_r/gun,
	$body/Armature/Skeleton/ulna_l/gun,
	$body/Armature/Skeleton/ulna_r/gun
]

var M_AOE := {
	"damage": 15,
	"min_range": 0,
	"max_range": 4,
	"min_angle":-PI,
	"max_angle": PI,
	"cooldown": 1.0,
	"move_speed": 0.5,
	"grounded":true,
	"name": "Swipe"
}

var M_DASH := {
	"damage":10,
	"min_range":3,
	"max_range":10,
	"min_angle":-PI/1.6,
	"max_angle":PI/1.6,
	"cooldown":1.0,
	"move_speed":7.0,
	"accel":60.0,
	"grounded":true,
	"name":"Dash"
}

var M_FIRE := {
	"damage":5,
	"min_range":3,
	"max_range":15,
	"min_angle":-PI,
	"max_angle":PI,
	"cooldown":0.5,
	"move_speed":1.0,
	"navigate":true,
	"blend":"HalfBody",
	"name":"Fire_Slow"
}

var M_DIVE := {
	"damage": 7,
	"min_range": 0.0,
	"max_range": 6.0,
	"min_angle":-PI/2,
	"max_angle":PI/2,
	"cooldown":0.5,
	"move_speed":1.0,
	"name":"Dive"
}

var M_GRAV_PANIC := {
	"damage":3,
	"min_range":0.0,
	"max_range":20.0,
	"min_angle":-PI,
	"max_angle":PI,
	"cooldown":3.0,
	"move_speed":1.0,
	"blend":"FullBody",
	"gravity_stunned":true,
	"name":"GravityPanic"
}

var moves := [
	M_AOE,
	M_DASH,
	M_FIRE,
	M_DIVE,
	M_GRAV_PANIC
]

var move_blends := [
	"HalfBody",
	"FullBody"
]

var ground_normal := Vector3.UP
var cooldown := 3.0
var current_move
var state_timer := 0.0
var was_on_floor := true
var starting_position:Transform
var starting_health := health
var starting_collision_layer = collision_layer
const GRAVITY_STUN_TIME := 5.5
var stun_timer := 0.0

onready var chest := $body/Armature/Skeleton/chest

func _init():
	damaged_objects = []

func _ready():
	if Global.is_picked(self.get_path()):
		die(true)
		global_transform = Global.stat("death"+get_path())
	elif activation_stat != "":
		if Global.stat("activation_stat"):
			ai_state = AIState.Chase
		elif !Global.is_connected("stat_changed", self, "_on_stat_changed"):
			var _x = Global.connect("stat_changed", self, "_on_stat_changed")

	if ai_state == AIState.Inactive or ai_state == AIState.Dead:
		set_physics_process(false)
	else:
		activate()
		if reset_on_player_death:
			if !player.is_connected("died", self, "_on_player_died"):
				var _x = player.connect("died", self, "_on_player_died")
				starting_position = global_transform
				starting_health = health
				starting_collision_layer = collision_layer
			else:
				global_transform = starting_position
				health = starting_health
				collision_layer = starting_collision_layer
				collision_mask = 3
				velocity = Vector3.ZERO

func _on_stat_changed(stat, value):
	if ai_state == AIState.Inactive and stat == activation_stat and value:
		activate()

func activate():
	player = Global.get_player()
	player_last_origin = player.global_transform.origin
	var _x = calculate_path(player_last_origin)
	ai_state = AIState.Chase
	move_anim.travel("Walk")
	set_physics_process(true)

func process_player_distance(pos: Vector3):
	return (pos - global_transform.origin).length_squared()

func _on_player_died():
	if !is_inside_tree():
		return
	if ai_state != AIState.Dead:
		_reset()

func _reset():
	_ready()

func _physics_process(delta):
	if !player:
		print_debug("Where's the player?")
		return
	
	match ai_state:
		AIState.Dead:
			move(delta, Vector3.ZERO)
			if is_on_floor():
				set_physics_process(false)
		AIState.Chase:
			chase(delta)
		AIState.MoveWindup:
			move(delta, Vector3.ZERO)
			var loc := player.global_transform.origin
			var dir := (loc - global_transform.origin).normalized()
			rotate_toward(dir, delta)
		AIState.MoveActive:
			var dir: Vector3
			if "navigate" in current_move and current_move.navigate:
				dir = get_direction()
			else:
				var loc := player.global_transform.origin
				dir = (loc - global_transform.origin).normalized()
			var accel: float
			if "accel" in current_move:
				accel = current_move.accel
			else:
				accel = ACCEL_GROUND
			move(delta, dir*chase_speed*current_move.move_speed, accel)
			rotate_toward(dir, delta)

func get_direction() -> Vector3:
	var loc = player.global_transform.origin
	var next_pos : Vector3
	if (loc - player_last_origin).length() > 1.0:
		next_pos = calculate_path(loc)
	else:
		next_pos = nav.get_next_location()
	return (next_pos - global_transform.origin).normalized()

func chase(delta):
	state_timer += delta
	var loc = player.global_transform.origin
	var dir := get_direction()
	var final_pos:Vector3 = nav.get_final_location()
	var final_diff := final_pos - global_transform.origin
	
	if move_state == MoveState.JumpCharge:
		if state_timer >= 0.4:
			velocity.y = get_jump_velocity(player.global_transform.origin - global_transform.origin)
			move_state = MoveState.Jumping
			move_anim.travel("Jump")
		else:
			ground_move(delta, Vector3.ZERO)
	elif move_state == MoveState.Jumping:
		dir = (player.global_transform.origin - global_transform.origin).normalized()
		air_move(delta, chase_speed*2*dir, 12.0)
		if is_on_floor():
			move_state = MoveState.Ground
			move_anim.travel("Walk")
			var _x = calculate_path(loc)
	else:
		cooldown -= delta
		if cooldown <= 0.0:
			var newmove = plot_attack()
			if newmove:
				execute(newmove)
		if final_diff.length() < 2 and move_state != MoveState.GravityStun:
			dir = Vector3.ZERO
			if !nav.is_target_reachable() and is_on_floor() and player.is_grounded():
				# TODO: calculate the path from the target to the end of our path
				# then jump to that point
				state_timer = 0.0
				move_state = MoveState.JumpCharge
				move_anim.travel("JumpCharge")
				animTree["parameters/WalkSpeed/scale"] = 1.0
		move(delta, chase_speed*dir)
	rotate_toward(dir, delta)

func get_target_ref():
	return chest.global_transform.origin

func plot_attack():
	var diff = player.global_transform.origin - global_transform.origin
	var dist = diff.length()
	diff /= diff
	diff.y = 0
	var angle = body.global_transform.basis.z.angle_to(diff)
	var best_move = null
	for m in moves:
		if best_move and best_move.damage > m.damage:
			continue
		if dist > m.max_range or dist < m.min_range:
			continue
		if angle < m.min_angle or angle > m.max_angle:
			continue 
		if move_state == MoveState.GravityStun:
			if !("gravity_stunned" in m) or !m.gravity_stunned:
				continue
		elif "grounded" in m and move_state:
			if is_on_floor() != m.grounded or (
				m.grounded and !nav.is_target_reachable()
			):
				continue
		elif "gravity_stunned" in m and m.gravity_stunned:
			continue
		best_move = m
		
	return best_move

func execute(move):
	current_move = move
	var anim:String = move.name
	if "anim" in move:
		anim = move.anim
	$attack_anim.play(anim)
	var blend := "FullBody"
	if "blend" in move:
		blend = move.blend

	var a:AnimationNodeAnimation = animTree.tree_root.get_node("Move" + blend)
	a.animation = anim
	animTree["parameters/%s/active" % blend] = true
	ai_state = AIState.MoveWindup

func walk_blend():
	var walk := velocity
	walk.y = 0
	# TODO: make default walk speed a constant
	walk /= 4.0
	var d := walk.dot(body.global_transform.basis.z)
	var speed = sign(d)*sqrt(abs(d))
	var b :float = animTree["parameters/Movement/Walk/blend_position"]
	var blend :float = lerp(b, speed, 0.1)
	animTree["parameters/Movement/Walk/blend_position"] = blend
	animTree["parameters/WalkSpeed/scale"] = max(blend, 0.5)

func end_windup():
	ai_state = AIState.MoveActive

func end_move():
	ai_state = AIState.Chase
	cooldown = current_move.cooldown
	$attack_anim.queue("RESET")
	damaged_objects = []

func get_jump_velocity(difference: Vector3) -> float:
	var a := abs(GRAVITY.y)
	var p := max(difference.y, 0.0) + 2.0

	# Air time at peak = v0/a
	# Height at a point in time = 0.5at^2 + v0t
	# Height at peak = 1.5*(v0^2/a)
	# Velocity to reach peak p = sqrt(2/3ap)
	var v0 := sqrt(2 * a * p)
	return v0

func move(delta:float, movement:Vector3, accel:float = ACCEL_GROUND):
	if move_state == MoveState.GravityStun:
		stun_timer += delta
		if stun_timer > GRAVITY_STUN_TIME:
			move_state = MoveState.Ground
			was_on_floor = false
			move_anim.travel("Fall")
		velocity *= 0.99
		velocity.y *= 0.99
		velocity = move_and_slide(velocity, Vector3.UP)
		return
	var on_ground: bool
	if was_on_floor:
		on_ground = !$GroundArea.get_overlapping_bodies().empty()
	else:
		on_ground = is_on_floor()
	if is_on_floor():
		ground_normal = get_floor_normal()
		
	if on_ground:
		if !was_on_floor:
			move_anim.travel("Walk")
		ground_move(delta, movement, accel)
		walk_blend()
	else:
		if was_on_floor:
			move_anim.travel("Fall")
			animTree["parameters/WalkSpeed/scale"] = 1.0
		air_move(delta, movement)
	was_on_floor = on_ground


func ground_move(delta: float, movement: Vector3, accel:float = ACCEL_GROUND):
	var gravity: Vector3
	if GRAVITY.dot(ground_normal) >= 0:
		gravity = Vector3.ZERO
	else:
		gravity = GRAVITY.project(ground_normal)
	var vy := velocity.y
	velocity.y = 0
	velocity = velocity.move_toward(movement, accel*delta)
	velocity.y += vy
	velocity += delta*gravity
	velocity = move_and_slide(
		velocity, 
		#Vector3.DOWN*0.25,
		Vector3.UP, false, 4, 0.5*PI)

func air_move(delta:float, movement: Vector3, accel_scale := 1.0):
	movement.y = 0
	var vy := velocity.y
	velocity.y = 0
	velocity = velocity.move_toward(movement, accel_scale*5.0*delta)
	velocity.y = vy
	velocity += delta*GRAVITY
	velocity = move_and_slide(velocity, Vector3.UP, false, 4, 1.7)

func rotate_toward(dir:Vector3, delta:float):
	var forward := body.global_transform.basis.z
	dir.y = 0
	var angle := forward.angle_to(dir)
	if abs(angle) > 0.01:
		var axis := forward.cross(dir).normalized()
		if !axis.normalized():
			axis = Vector3.UP
		var rot := sign(angle)*min(abs(angle), delta*10.0)
		body.global_rotate(axis, rot)

func calculate_path(loc: Vector3) -> Vector3:
	if !(nav.get_navigation() is Navigation):
		if has_node(navigation):
			nav.set_navigation(get_node(navigation))
		else:
			die()
	nav.set_target_location(loc)
	player_last_origin = loc
	var next = nav.get_next_location()
	
	if false:
		debug_path.clear()
		debug_path.begin(Mesh.PRIMITIVE_LINE_STRIP)
		for c in nav.get_nav_path():
			debug_path.add_vertex(c)
		debug_path.end()
	return next

func fire(id: int = -1):
	if id < 0:
		for c in guns:
			fire_from(c.global_transform)
	else:
		fire_from(guns[id].global_transform)

func fire_from(point: Transform):
	var proj
	if ObjectPool.has("orb"):
		proj = ObjectPool.get("orb")
	else:
		proj = orb.instance()
	
	get_tree().current_scene.add_child(proj)
	proj.source = self
	proj.damage = current_move.damage
	proj.speed = 2.0
	proj.turn_speed = 8.0
	proj.global_transform.origin = point.origin
	proj.fire(player, Vector3.UP*0.5, 20.0)
	proj.velocity = 6.0*point.basis.z

func _on_hitbox_entered(b):
	if b in damaged_objects:
		return
	if current_move and b.has_method("take_damage"):
		var dir = (b.global_transform.origin - global_transform.origin).normalized()
		b.take_damage(current_move.damage, dir, self)
		damaged_objects.append(b)

func take_damage(damage:int, dir:Vector3, source:Node, _tag := ""):
	if source == self:
		return
	# TODO: Other activation conditions
	if ai_state == AIState.Inactive:
		activate()
	velocity += dir*damage
	health -= damage
	if health <= 0.0:
		die()

func gravity_stun(damage):
	take_damage(damage, Vector3.UP, Global.get_player())
	if ai_state != AIState.Dead:
		move_anim.travel("GravityStunned")
		animTree["parameters/WalkSpeed/scale"] = 1.0
		if move_state != MoveState.GravityStun:
			end_move()
		move_state = MoveState.GravityStun
		stun_timer = 0.0

func die(on_start := false):
	if !on_start:
		emit_signal("died", "beauty", get_path())
	# Todo: rapidly go to the end when on startup
	move_anim.start("Die")
	$attack_anim.play("RESET")
	for blend in move_blends:
		animTree["parameters/%s/active" % blend] = false
	animTree["parameters/WalkSpeed/scale"] = 1.0
	ai_state = AIState.Dead
	collision_layer = 0
	collision_mask = 1
	Global.mark_picked(self.get_path())
	Global.set_stat("death"+get_path(), global_transform)
