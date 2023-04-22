extends EnemyBody

export(float) var orb_speed := 9.0
export(float) var orb_seeking := 1.2
export(float) var gun_cooldown := 1.5

const time_damaged := 2.0
var state_timer := 0.0
const MIN_DOT_DAMAGE := 0.2

var cooldown: PoolRealArray = [0.0, 0.0, 0.0, 0.0]

onready var guns = [$gun0, $gun1, $gun2, $gun3]

func _init():
	damaged_speed = 0.0

func _physics_process(delta):
	state_timer += delta
	match ai:
		AI.Idle:
			set_physics_process(false)
		AI.Chasing:
			for i in range(cooldown.size()):
				cooldown[i] -= delta
				if cooldown[i] < 0:
					cooldown[i] = 0
			if no_target():
				set_state(AI.Idle)
			for i in range(guns.size()):
				var gun = guns[i]
				var a:Area = gun.get_node("awareness")
				if a.overlaps_body(target) and cooldown[i] <= 0:
					fire_orb(gun.global_transform.origin, orb_speed, orb_seeking)
					cooldown[i] = gun_cooldown
		AI.Damaged:
			if state_timer > time_damaged:
				set_state(AI.Chasing)
		AI.GravityStun:
			stunned_move(delta)
			if state_timer > Global.gravity_stun_time:
				set_state(AI.Chasing)
		AI.GravityStunDead:
			stunned_move(delta)
			if state_timer > Global.gravity_stun_time:
				set_state(AI.Dead)
		AI.Dead:
			set_physics_process(false)

func take_damage(damage, dir, source, _tag := ""):
	if (source and source != self) or dir.y < MIN_DOT_DAMAGE:
		return
	else:
		if last_attacker:
			target = last_attacker
		.take_damage(damage, dir, source)

func set_state(new_ai, _force := false):
	state_timer = 0.0
	ai = new_ai
	gravity_scale = 1
	match ai:
		AI.Chasing:
			for i in range(cooldown.size()):
				cooldown[i] = randf()*gun_cooldown
		AI.GravityStun, AI.GravityStunDead:
			gravity_scale = 0

func _reset():
	._ready()
	_ready()
