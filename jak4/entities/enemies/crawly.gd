extends EnemyBody

export(float) var run_speed = 8.5
export(float) var lunge_speed = 15.0
export(float) var acceleration = 120.0
export(float) var deceleration = 10.0
export(float) var lunge_impules = 25.0
export(float) var turn_speed_radians = 60.0
export(float) var turn_speed_windup = 50.0
export(float) var turn_speed_attacking = 5.0
export(float) var accel_lunge := 25.0
export(float) var accel_fall := 1.0
export(AudioStream) var alert_audio
export(AudioStream) var run_audio
export(AudioStream) var death_audio
export(AudioStream) var damage_audio
export(AudioStream) var quit_audio
export(AudioStream) var attack_audio

export(float) var windup_time := .5
export(float) var attack_charge_time := 0.1
export(float) var attack_time := 0.3
export(float) var attack_end_time := 0.75
export(float) var alert_time := 2.0
export(float) var damaged_time := 1.0
export(float) var cooldown_time := 2.0
export(float) var extra_chase_time := 10.0

const MIN_DOT_GROUND := 0.7
const MIN_DOT_UP := 0.01


var state_timer := 0.0
var cooldown_timer := 0.0
var give_up_timer := 0.0

var ground_normal := Vector3.UP

onready var anim := $AnimationPlayer
onready var sound := $AudioStreamPlayer3D
onready var ref_target = $ref_target
var attack_player : AudioStreamPlayer3D

func _init():
	skip_alert = false

func _ready():
	if has_node("attack_audio"):
		attack_player = $attack_audio
	else:
		attack_player = sound

	anim.play("Idle-loop")

func _physics_process(delta):
	state_timer += delta
	if cooldown_timer > 0:
		cooldown_timer -= delta
	var next = ai
	match ai:
		AI.Idle:
			set_physics_process(false)
		AI.Alerted:
			if state_timer > alert_time:
				next = AI.Chasing
		AI.Chasing:
			if no_target():
				next = AI.Idle
			elif !awareness.overlaps_body(target):
				give_up_timer += delta
				if give_up_timer > extra_chase_time:
					next = AI.Idle
			elif contact_count and cooldown_timer <= 0 and $attack_range.overlaps_body(target):
				next = AI.Windup
			else:
				give_up_timer = 0.0
		AI.Windup:
			if state_timer > windup_time:
				next = AI.Attacking
		AI.Attacking:
			if state_timer > attack_end_time:
				next = AI.Chasing
		AI.Damaged:
			if state_timer > damaged_time:
				next = AI.Chasing
		AI.GravityStun:
			if state_timer > Global.gravity_stun_time:
				next = AI.Chasing
		AI.GravityStunDead:
			if state_timer > Global.gravity_stun_time:
				next = AI.Dead
	set_state(next)
	
	match ai:
		AI.Attacking:
			look_at_target(turn_speed_attacking, 1.5)
			walk(lunge_speed, accel_lunge, deceleration)
			if state_timer > attack_charge_time and state_timer < attack_time:
				damage_direction($hurtbox, global_transform.basis.z)
		AI.Chasing:
			ground_normal = get_closest_floor()
			if ground_normal.y > MIN_DOT_UP:
				rotate_up(turn_speed_radians*delta, ground_normal)
			look_at_target(turn_speed_radians, 2.5)
			if contact_count:
				walk(run_speed, acceleration, deceleration)
			else:
				walk(run_speed, accel_fall, deceleration)
		AI.Damaged:
			look_at_target(turn_speed_radians, 1.0)
		AI.Dead:
			set_physics_process(false)
			pass
		AI.Idle:
			walk(0, acceleration)
		AI.Windup, AI.Alerted:
			look_at_target(turn_speed_windup, 1.5)
			walk(0, acceleration)
		AI.GravityStun, AI.GravityStunDead:
			stunned_move(delta)

func set_active(active: bool):
	if !active:
		anim.stop()
		if ai == AI.Idle:
			set_physics_process(false)
			mode = MODE_STATIC
	else:
		mode = MODE_RIGID
		set_physics_process(true)
		set_state(ai, true)

func play_damage_sfx():
	sound.stream = damage_audio
	sound.play()

func get_shield():
	if is_inside_tree():
		return $debug_shield
	else:
		return null

func get_target_ref():
	return ref_target.global_transform.origin

func set_state(new_ai, force := false):
	if ai == new_ai and !force:
		return
	if ai == AI.Attacking:
		cooldown_timer = cooldown_time
	else:
		cooldown_timer = 0
	ai = new_ai
	state_timer = 0
	damaged = []
	gravity_scale = 1
	match ai:
		AI.Alerted:
			anim.play("Alert")
			sound.stream = alert_audio
			sound.play()
		AI.Chasing:
			sleeping = false
			sound.stream = run_audio
			sound.play()
			anim.play("Run-loop")
		AI.Damaged:
			sound.stop()
			sound.stream = damage_audio
			sound.play()
			sleeping = false
			if last_attacker:
				aggro_to(last_attacker)
			anim.play("Damaged")
		AI.Dead:
			angular_damp = 10
			linear_damp = 5
			gravity_scale = 8
			collision_layer = 0
			anim.play("Die")
			anim.queue("Dead-loop")
			sound.stream = death_audio
			sound.play()
			if attack_player != sound:
				attack_player.stop()
		AI.Idle:
			anim.play("Idle-loop")
			sound.stream = quit_audio
			sound.play()
		AI.Windup:
			sleeping = false
			anim.play("Attack")
			sound.stop()
			attack_player.stream = attack_audio
			attack_player.play()
		AI.GravityStun:
			sleeping = false
			anim.play("GravityStun-loop")
			gravity_scale = 0
			sound.stop()
		AI.GravityStunDead:
			gravity_scale = 0
		AI.Attacking:
			apply_central_impulse(global_transform.basis.z*lunge_impules*mass)

func step(leftForward: bool):
	if !best_floor:
		return
	var leg0: Vector3
	var leg1: Vector3
	if leftForward:
		leg0 = $Armature/Skeleton/legfl.global_transform.origin
		leg1 = $Armature/Skeleton/legbr.global_transform.origin
	else:
		leg0 = $Armature/Skeleton/legfr.global_transform.origin
		leg1 = $Armature/Skeleton/legbl.global_transform.origin
	Bumps.impact_on(best_floor, Bumps.Impact.ImpactLight, leg0, best_floor_normal)
	Bumps.impact_on(best_floor, Bumps.Impact.ImpactLight, leg1, best_floor_normal)

func _reset():
	._ready()
	_ready()
