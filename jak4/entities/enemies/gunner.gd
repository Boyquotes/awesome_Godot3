extends EnemyBody

export(float) var bounce_damage := 5.0
export(float) var aim_speed := 0.6
export(float) var aim_speed_windup := 0.35
export(float) var time_to_shoot := 3.0
export(float) var flee_radius := 5.0
export(float) var safe_radius := 10.0
export(float) var bounce_impulse := 5.0
export(float) var bounce_impulse_h := 8.0
export(float) var flee_acceleration := 40.0

export(Color) var laser_color := Color(3, 0.2, 0.2)

const TIME_WINDUP := 0.5
const TIME_ATTACK := 1.0
const TIME_DAMAGED := 0.4
const TIME_QUIT := 5.0

const BOUNCE_WINDUP_TIME := 0.75
const BOUNCE_TIME_TO_HITBOX := 0.1
const BOUNCE_MIN_TIME := 0.25
const BOUNCE_TURN_SPEED := 300.0
const DEFAULT_DISTANCE := 20.0

const GRAV_STUN_TURN_SPEED := 10.0

var shot_timer := 0.0
var state_timer := 0.0
var quit_timer := 0.0
var bounce_timer := 0.0

var grounded := true

onready var laser := $laser
onready var laser_geo := $laser/geomentry
onready var aim_cast := $laser/aim_cast
onready var groundArea := $ground_area
onready var clawHitbox := $claw_hitbox
onready var anim:AnimationNodeStateMachinePlayback = $AnimationTree["parameters/StateMachine/playback"]
onready var anim_tree := $AnimationTree

func _ready():
	reset_aim()
	aim_cast.add_excluded_object(self.get_rid())

func _physics_process(delta):
	state_timer += delta
	var dist: Vector3
	if target:
		dist = target.global_transform.origin - global_transform.origin
	
	match ai:
		AI.Idle:
			set_physics_process(false)
		AI.Chasing:
			shot_timer += delta
			if no_target():
				set_state(AI.Idle)
				retarget()
			else:
				if !awareness.overlaps_body(target):
					quit_timer += delta
				else:
					quit_timer = 0.0
				
				if quit_timer >= TIME_QUIT:
					set_state(AI.Idle)
				elif shot_timer >= time_to_shoot:
					set_state(AI.Windup)
				elif dist.length_squared() < flee_radius*flee_radius:
					if !shielded or dist.normalized().dot(global_transform.basis.z) < min_dot_shielded_damage + 0.5:
						set_state(AI.Flee)
			var f := DEFAULT_DISTANCE/(1 + dist.length())
			aim(delta, f*aim_speed)
			walk(0, 100)
		AI.Windup:
			if state_timer > TIME_WINDUP:
				set_state(AI.Attacking)
			var f := DEFAULT_DISTANCE/(1 + dist.length())
			aim(delta, f*aim_speed_windup)
			walk(0, 100)
		AI.Attacking:
			if state_timer > TIME_ATTACK:
				set_state(AI.Chasing)
			walk(0, 100)
		AI.Damaged:
			if state_timer > TIME_DAMAGED:
				set_state(AI.Chasing)
			walk(0, 100)
		AI.Flee:
			if no_target():
				set_state(AI.Idle)
			else:
				bounce_timer += delta
				dist.y = 0
				var dir := -dist.normalized()
				var safe_dist := dist.length_squared() > safe_radius*safe_radius
				var safe_angle := dist.normalized().dot(global_transform.basis.z) > 0.2
				if grounded:
					if safe_angle and safe_dist:
						set_state(AI.Chasing)
						
					walk(0, 100)

					if bounce_timer > BOUNCE_WINDUP_TIME:
						if safe_dist:
							dir = Vector3.ZERO
						apply_central_impulse(mass*(Vector3.UP*bounce_impulse + dir*bounce_impulse_h))
						grounded = false
						bounce_timer = 0
						damaged = []
					elif !groundArea.get_overlapping_bodies().size() > 0:
						grounded = false
				else:
					look_at_target(BOUNCE_TURN_SPEED*delta)
					look_at_target(BOUNCE_TURN_SPEED*delta)
					if bounce_timer > BOUNCE_MIN_TIME and is_grounded():
						anim.travel("Flee_Windup")
						grounded = true
						bounce_timer = 0
					if bounce_timer > BOUNCE_TIME_TO_HITBOX:
						damage_direction(clawHitbox, -dir, bounce_damage)
		AI.GravityStun:
			look_at_target(GRAV_STUN_TURN_SPEED*delta)
			stunned_move(delta)
			if state_timer > Global.gravity_stun_time:
				set_state(AI.Chasing)
		AI.GravityStunDead:
			stunned_move(delta)
			if state_timer > Global.gravity_stun_time:
				set_state(AI.Dead)
		AI.Dead:
			set_physics_process(false)
	aim_cast.update()

func reset_aim():
	laser.rotation_degrees = Vector3.ZERO
	anim_tree["parameters/StateMachine/Aim/blend_position"] = Vector2.ZERO

func aim(delta: float, speed: float):
	if target:
		var target_pos: Vector3
		if target.has_method("get_target_ref"):
			target_pos = target.get_target_ref()
		else:
			target_pos = target.global_transform.origin
		
		var aim_dir: Vector3 = (target_pos - laser.global_transform.origin).normalized()
		if aim_dir.is_normalized():
			if aim_dir.dot(global_transform.basis.z) < 0:
				set_state(AI.Flee)
			var f:Vector3 = laser.global_transform.basis.z
			var angle :float = f.angle_to(aim_dir)
			if abs(angle) > 0.0:
				var axis := f.cross(aim_dir).normalized()
				if axis.is_normalized():
					var rot := sign(angle)*min(abs(angle), speed*delta)
					laser.global_rotate(axis, rot)
		var aim_up :float = laser.global_transform.basis.z.dot(global_transform.basis.y)
		var aim_right :float = laser.global_transform.basis.z.dot(-global_transform.basis.x)
		anim_tree["parameters/StateMachine/Aim/blend_position"] = Vector2(aim_right, aim_up)

func get_shield():
	if is_inside_tree():
		return $debug_shield
	else:
		return null

func get_target_ref():
	return $target.global_transform.origin

func fire():
	damaged = []
	var c = aim_cast.get_hit_collider()
	if !c:
		return
	if c.has_method("take_damage"):
		c.take_damage(attack_damage, laser.global_transform.basis.z, self)
	var particles := $impact/Particles
	particles.emitting = false
	particles.global_transform.origin = (
		aim_cast.global_transform.origin 
		+ aim_cast.global_transform.basis.z*aim_cast.get_hit_length())
	particles.emitting = true

func set_state(new_ai, _force := false):
	grounded = true
	state_timer = 0.0
	ai = new_ai
	if !laser:
		return
	
	var mat_laser: SpatialMaterial = laser_geo.material_override
	gravity_scale = 1
	match ai:
		AI.Idle:
			anim.travel("Idle")
			laser.hide()
		AI.Chasing:
			quit_timer = 0.0
			shot_timer = 0.0
			anim.travel("Aim")
			mat_laser.albedo_color = laser_color
			laser.show()
		AI.Windup:
			laser.show()
			mat_laser.albedo_color = Color(3,3,3)
		AI.Attacking:
			shot_timer = 0.0
			fire()
		AI.Flee:
			sleeping = false
			anim.travel("Flee_Windup")
			laser.hide()
		AI.Dead:
			collision_layer = 0
			sleeping = false
			anim.travel("Death")
			laser.hide()
		AI.Damaged:
			sleeping = false
			if last_attacker:
				aggro_to(last_attacker)
			anim.travel("Damaged")
		AI.GravityStun:
			gravity_scale = 0
			sleeping = false
			anim.travel("GravityStun")
		AI.GravityStunDead:
			gravity_scale = 0

func _reset():
	._ready()
	_ready()
