extends EnemyBody
class_name DeathGnat

export(float) var speed := 5.0
export(float) var acceleration := 1.0
export(float) var turn_speed = 100.0
export(float) var orb_cooldown := 2.0
export(float) var orb_speed := 5.0
export(float) var orb_seeking := 2.0
export(float) var time_to_quit = 10.0
export(float) var minimum_radius = 5.0
export(float) var maximum_radius = 10.0
export(float) var desired_height = 3.0
export(AudioStream) var damaged_sound
export(AudioStream) var death_sound

const TIME_FLINCH := 0.75
var state_timer := 0.0
var quit_timer := 0.0
var orb_timer := 0.0

func _init():
	can_fly = true

func _ready():
	axis_lock_angular_x = true
	axis_lock_angular_z = true

func set_active(active):
	if active:
		sleeping = false
		$AnimationPlayer.play("Idle-loop", -1, 0.5)
		set_physics_process(true)
		mode = MODE_RIGID
	else:
		$AnimationPlayer.stop()
		if ai == AI.Idle:
			mode = MODE_STATIC
			set_physics_process(false)

func _physics_process(delta):
	state_timer += delta
	if orb_timer > 0:
		orb_timer = max(orb_timer - delta, 0)
	var next_state = ai
	match ai:
		AI.Idle:
			set_physics_process(false)
		AI.Chasing:
			if no_target():
				next_state = AI.Idle
			elif awareness.get_overlapping_bodies().size() == 0:
				quit_timer += delta
				if quit_timer > time_to_quit:
					print("I Quit!")
					next_state = AI.Idle
			else:
				quit_timer = 0
		AI.Windup:
			pass
		AI.Attacking:
			pass
		AI.Damaged:
			if state_timer > TIME_FLINCH:
				next_state = AI.Chasing
		AI.GravityStun:
			if state_timer > Global.gravity_stun_time:
				next_state = AI.Chasing
		AI.Dead:
			set_physics_process(false)
		AI.GravityStunDead:
			if state_timer > Global.gravity_stun_time:
				next_state = AI.Dead
	set_state(next_state)
	
	match ai:
		AI.Idle:
			fly()
			pass
		AI.Chasing:
			look_at_target(delta*turn_speed)
			fly()
			if orb_timer <= 0:
				fire_orb($orb_spawner.global_transform.origin, orb_speed, orb_seeking)
				orb_timer = orb_cooldown
		AI.Damaged:
			look_at_target(delta*turn_speed)
		AI.Dead:
			fall_down(delta)
		AI.GravityStun, AI.GravityStunDead:
			stunned_move(delta)

func fly():
	var desired_position: Vector3 
	var desired_velocity: Vector3
	var exit_radius = minimum_radius
	if !target:
		desired_position = global_transform.origin
		exit_radius = 0
	else:
		desired_position = target.global_transform.origin + Vector3.UP*desired_height
		if target is PlayerBody:
			desired_velocity = target.velocity
			if desired_velocity.length_squared() > speed*speed:
				desired_velocity = desired_velocity.normalized()*speed
		elif target is RigidBody:
			desired_velocity = target.linear_velocity
	var dir := desired_position - global_transform.origin
	var l = Vector2(dir.x, dir.z).length_squared()
	dir = dir.normalized()
	if l < exit_radius*exit_radius:
		dir.x = -dir.x
		dir.z = -dir.z
	elif l < maximum_radius*maximum_radius:
		dir.x = 0
		dir.z = 0
	
	desired_velocity += speed*dir
	
	var force := acceleration*(desired_velocity - linear_velocity)
	
	add_central_force(force*mass)

func play_damage_sfx():
	# TODO
	pass

func take_damage(damage, dir, source, tag := ""):
	if source == self:
		return
	else:
		.take_damage(damage, dir, source, tag)

func get_shield():
	if is_inside_tree():
		return $debug_shield
	else:
		return null

func set_state(new_state, force:=false):
	if !force and ai == new_state:
		return
	ai = new_state
	state_timer = 0
	gravity_scale = 0
	match ai:
		AI.Idle:
			target = null
		AI.Chasing:
			$AnimationPlayer.play("Idle-loop")
			quit_timer = 0
			orb_timer = orb_cooldown
		AI.Dead:
			$AudioStreamPlayer3D.stream = death_sound
			$AudioStreamPlayer3D.play()
			axis_lock_angular_x = false
			axis_lock_angular_z = false
			gravity_scale = 1
			$AnimationPlayer.stop()
			collision_layer = 0
		AI.Damaged:
			$AudioStreamPlayer3D.stream = damaged_sound
			$AudioStreamPlayer3D.play()
			if speed == 0:
				speed = 5.0
			gravity_scale = 1
			if last_attacker:
				aggro_to(last_attacker)
			$AnimationPlayer.stop()
		AI.GravityStun:
			$AnimationPlayer.stop()
			$AnimationPlayer.play("GravityStun-loop")
		AI.GravityStunDead:
			pass
		_:
			$AnimationPlayer.play("Idle-loop")

func _reset():
	._ready()
	_ready()
