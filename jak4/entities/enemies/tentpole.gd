extends EnemyBody

export(float) var run_speed = 6.5
export(float) var turn_speed_radians = 40.0
export(float) var acceleration := 60.0

onready var anim := $AnimationTree
onready var playback:AnimationNodeStateMachinePlayback = anim["parameters/StateMachine/playback"]
onready var chopper_hitbox:Area = $Armature/Skeleton/chopper/Area

const TIME_TO_QUIT := 12.0
const TIME_ALERT := 1.0
const TIME_DAMAGED := 0.8
var quit_timer := 0.0
var state_timer := 0.0

func _ready():
	mode = MODE_STATIC

func _physics_process(delta):
	state_timer += delta
	match ai:
		AI.Idle:
			set_physics_process(false)
		AI.Alerted:
			if !target:
				set_state(AI.Idle)
			elif state_timer > TIME_ALERT:
				set_state(AI.Chasing)
			look_at_target(turn_speed_radians)
		AI.Chasing:
			if no_target():
				set_state(AI.Idle)
			elif !awareness.overlaps_body(target):
				quit_timer += delta
				if quit_timer > TIME_TO_QUIT:
					set_state(AI.Idle)
			else:
				quit_timer = 0
			look_at_target(turn_speed_radians)
			walk(run_speed, acceleration)
		AI.Damaged:
			if state_timer >= TIME_DAMAGED:
				set_state(AI.Chasing)
			look_at_target(turn_speed_radians)
			walk(0, acceleration)
		AI.Dead:
			set_physics_process(false)
		AI.GravityStun:
			stunned_move(delta)
			if state_timer > Global.gravity_stun_time:
				set_state(AI.Chasing)
		AI.GravityStunDead:
			stunned_move(delta)
			if state_timer > Global.gravity_stun_time:
				set_state(AI.Dead)
			

func take_damage(damage, dir, source, _tag := ""):
	if source and source != self:
		return
	else:
		if last_attacker:
			target = last_attacker
		.take_damage(damage, dir, source)

func set_state(new_ai, _force := false):
	ai = new_ai
	state_timer = 0
	gravity_scale = 1
	if ai != AI.Idle and mode != MODE_RIGID:
		mode = MODE_RIGID
	match ai:
		AI.Idle:
			chopper_hitbox.active = false
			playback.travel("Idle-loop")
		AI.Alerted:
			playback.travel("Chase")
		AI.Chasing:
			sleeping = false
			chopper_hitbox.active = true
			playback.travel("Chase")
		AI.Damaged:
			sleeping = false
			target = Global.get_player()
			if playback.get_current_node() == "Chase":
				anim["parameters/StateMachine/Chase/Damaged/active"] = true
			else:
				playback.travel("Damaged")
		AI.Dead:
			chopper_hitbox.active = false
			playback.travel("Death")
			$CollisionShape.disabled = true
			$CollisionShape2.disabled = true
			collision_layer = 0
			if has_node("Armature/Skeleton/head"):
				$Armature/Skeleton/head.queue_free()
		AI.GravityStun:
			sleeping = false
			chopper_hitbox.active = true
			playback.travel("GravityStun")
			gravity_scale = 0
		AI.GravityStunDead:
			gravity_scale = 0

func _reset():
	._ready()
	_ready()
