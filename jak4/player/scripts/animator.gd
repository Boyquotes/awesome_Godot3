extends Spatial

var sounds := {
	"stepSteepGround": [
		preload("res://audio/player/stepsteep2.wav"),
		preload("res://audio/player/stepsteep3.wav"),
		preload("res://audio/player/stepsteep4.wav"),
	],
	"climb_hand":[
		preload("res://audio/player/climb_hand1.wav"),
		preload("res://audio/player/climb_hand2.wav")
	],
	"climb_step": [
		preload("res://audio/player/stepsteep2.wav"),
		preload("res://audio/player/stepsteep3.wav"),
		preload("res://audio/player/stepsteep4.wav"),
	],
	"dive_windup":[
		preload("res://audio/player/lunge_kick1.wav")
	],
	"dive_start": [
		preload("res://audio/player/dive_start1.wav")
	],
	"crouch_jump": [
		preload("res://audio/player/crouch_jump1.wav")
	],
	"jump": [
		preload("res://audio/player/jump1.wav")
	],
	"gem": [
		preload("res://audio/pickup/gem1.wav"),
		preload("res://audio/pickup/gem2.wav"),
	],
	"coat": [
		preload("res://audio/pickup/coat1.wav"),
		preload("res://audio/pickup/coat2.wav"),
	],
	"wep_pistol": [
		preload("res://audio/pickup/wep_pistol.wav")
	],
	"wep_wave_shot": [
		preload("res://audio/pickup/wep_wave_shot.wav")
	],
	"wep_grav_gun": [
		preload("res://audio/pickup/wep_grav_shot.wav")
	],
	"pistol":[
		preload("res://audio/pickup/ammo.wav")
	],
	"_pickup": [
		preload("res://audio/pickup/gem1.wav"),
		preload("res://audio/pickup/gem2.wav"),
	]
}

export(AudioStream) var sound_roll : AudioStream
export(AudioStream) var sound_roll_jump : AudioStream
export(AudioStream) var sound_lunge_kick : AudioStream
export(AudioStream) var sound_spin_kick : AudioStream
export(AudioStream) var sound_uppercut : AudioStream

onready var anim: AnimationTree = $AnimationTree
onready var anim_player: AnimationPlayer = $anim
onready var anim_tree: AnimationNodeBlendTree = anim.tree_root
onready var custom_node: AnimationNodeAnimation = anim_tree.get_node("WholeBody").get_node("CustomAnimation")
onready var custom_loop_node: AnimationNodeAnimation = anim_tree.get_node("WholeBody").get_node("CustomLoop")
onready var custom_loop_node2: AnimationNodeAnimation = anim_tree.get_node("WholeBody").get_node("CustomLoop2")
onready var custom_exit_node: AnimationNodeAnimation = anim_tree.get_node("WholeBody").get_node("CustomExit")
onready var single_custom :AnimationNodeAnimation = anim_tree.get_node("WholeBody").get_node("Single")

onready var attack_sounds :AudioStreamPlayer = $audio/attack
onready var body: AnimationNodeStateMachinePlayback = anim["parameters/WholeBody/playback"]
onready var player = get_parent()
onready var audio := $audio

onready var camera_rig := $"../camera_rig"
onready var hover_board := $Armature/Skeleton/hover_board
onready var aim_reference := $Armature/Skeleton/lumbar/body_reference

onready var gun_tween := $Armature/Skeleton/gun/Tween

var item_sound := 0
var move_blend:= 0.0
var lunge_right_foot := true
var held_item:Spatial

func _input(event):
	if event.is_action_pressed("debug_toggle_animator"):
		anim.active = !anim.active

func _ready():
	hover_board.hide()
	var _x = TimeManagement.connect("time_scale_changed", self, "_on_time_scale_changed")

func _on_time_scale_changed(_time_scale):
	$Armature/Skeleton/chest/time_trail.set_active(TimeManagement.time_slowed)

func blend_run_animation(movement: Vector3):
	var speed: float = movement.length()
	if speed < 0.01:
		speed = 0
	var a = anim["parameters/WholeBody/Walk/blend_position"]
	speed = lerp(a, speed, 0.3)
	anim["parameters/WholeBody/Walk/blend_position"] = speed
	anim["parameters/WholeBody/Crouch/blend_position"] = speed
	anim["parameters/WholeBody/Slide/blend_position"] = speed
	anim["parameters/WholeBody/Wading/blend_position"] = speed

func blend_climb_animation(velocity: Vector3, wall_normal: Vector3):
	var b :Vector2 = anim["parameters/WholeBody/Climb/0/blend_position"]
	var right := -global_transform.basis.x.dot(velocity)
	var up := 0.0
	up = velocity.y
	b =  lerp(b, Vector2(right, up), 0.3)
	anim["parameters/WholeBody/Climb/0/blend_position"] = b
	anim["parameters/WholeBody/Climb/1/blend_position"] = b
	
	var slope: float = anim["parameters/WholeBody/Climb/blend_position"]
	anim["parameters/WholeBody/Climb/blend_position"] = lerp(wall_normal.y, slope, 0.3)

func force_play(state):
	body.call_deferred("start", state)

func play_custom(animation):
	if !anim_player.has_animation(animation):
		print_debug("No animation: ", animation)
	custom_node.animation = animation
	body.travel("CustomAnimation")

func play_custom_loop(transition: String, end_point: String):
	var c : String
	custom_node.animation = transition
	if body.get_current_node() == "CustomLoop":
		print("Transitioning to 2")
		c = "CustomLoop2"
		custom_loop_node2.animation = end_point
	else:
		c = "CustomLoop"
		custom_loop_node.animation = end_point
		
	body.travel(c)

func step(right: bool):
	if (player.best_floor 
		and player.velocity.length_squared() > 0.01
		and player.after(0.1)
	):
		var foot : Spatial
		if right:
			foot = $Armature/Skeleton/footRight
		else:
			foot = $Armature/Skeleton/footLeft
		Bumps.step_on(player.best_floor, foot.global_transform.origin, false, player.ground_normal)

func play_single(a: String):
	if !anim_player.has_animation(a):
		print_debug("MISSING: ", a)
	single_custom.animation = a
	body.travel("Single")

func exit_custom_loop(transition:String):
	if !anim_player.has_animation(transition):
		print_debug("MISSING: ", transition)
	custom_exit_node.animation = transition
	body.travel("CustomExit")

func transition_to(state):
	body.call_deferred("travel", state)

func show_coat(coat: Coat):
	var mat = coat.generate_material()
	$Armature/Skeleton/coat.material_override = mat

func play_sound(bodyPart: String, soundType: String, randomize_tone := false):
	if soundType.begins_with("step") and player.velocity.length_squared() < 0.002:
		return
	if !audio.has_node(bodyPart):
		print_debug("No audio player for ", bodyPart)
		return
	var node = audio.get_node(bodyPart)
	node.stream = get_random_sound(soundType)
	if node.stream == null:
		print("No sound: ", soundType)
		return
	if randomize_tone:
		node.pitch_scale = rand_range(0.9, 1.2)
	node.play()

func get_desired_aim():
	return -player.intention.global_transform.basis.z

func get_random_sound(type: String) -> AudioStream:
	if type == "step":
		type = "stepLevelGround"
	if !(type in sounds) or sounds[type].size() == 0:
		return null
	var array: Array = sounds[type]
	return array[randi() % array.size()]

func stop_particles():
	$max_dive_particles.emitting = false
	$dive_particles.emitting = false

func ground_transition(state: String):
	transition_to(state)

func play_jump():
	play_sound("feet", "jump", true)
	transition_to("BaseJump")

func play_high_jump():
	play_sound("feet", "crouch_jump", true)
	transition_to("HighJump")

func play_ledge_jump():
	play_sound("attack", "crouch_jump", true)
	transition_to("BaseJump")

func play_crouch_jump():
	play_sound("attack", "crouch_jump", true)
	play_sound("feet", "jump", true)
	transition_to("BaseJump")

func play_dodge():
	$Armature/Skeleton/head/perfect_dodge/AnimationPlayer.play("dodged")

func play_roll():
	play_attack_sound(sound_roll)
	transition_to("Roll")

func play_roll_jump(_max_damage: bool):
	#if _max_damage:
	#	start_roll_particles()
	transition_to("RollJump")
	play_attack_sound(sound_roll_jump)
	play_sound("feet", "jump", true)

func play_dive_windup(__max_damage: bool):
	play_sound("attack", "dive_windup", true)
	transition_to("DiveStart")

func play_dive_start(_max_damage: bool):
	#start_kick_left(_max_damage)
	play_sound("attack", "dive_start")

func play_dive_end(_max_damage: bool):
	play_sound("attack", "dive_end", true)
	transition_to("DiveEnd")
	#start_dive_shockwave(_max_damage)

func play_spin_kick(_max_damage: bool):
	force_play("SpinKickLeft")
	#start_kick_left(_max_damage)
	play_attack_sound(sound_spin_kick)

func play_uppercut(_max_damage: bool):
	#start_kick_left(_max_damage)
	#start_kick_right(_max_damage)
	play_attack_sound(sound_uppercut)

func play_lunge_kick(_max_damage: bool):
	anim["parameters/WholeBody/LungeKick/blend_position"] = float(lunge_right_foot)
	transition_to("LungeKick")
	#if lunge_right_foot:
	#	start_kick_right(_max_damage)
	#else:
	#	start_kick_left(_max_damage)
	lunge_right_foot = !lunge_right_foot
	play_attack_sound(sound_lunge_kick)

func play_attack_sound(sound: AudioStream):
	attack_sounds.pitch_scale = 1.0
	attack_sounds.stop()
	attack_sounds.stream = sound
	attack_sounds.play()

func play_sit():
	transition_to("Sitting_Floor")

func play_ledge_grab():
	transition_to("LedgeGrab")

func start_dive_shockwave(_max_damage: bool):
	$dive_particles.emitting = true
	if _max_damage:
		$max_dive_particles.emitting = true

func start_damage_particle(dir: Vector3):
	var emitter := $Armature/Skeleton/chest/damage_particles
	dir.y = 0.5
	var local_dir: Vector3 = emitter.global_transform.basis.inverse()*(dir).normalized()
	emitter.process_material.direction = local_dir
	emitter.emitting = true
	yield(get_tree().create_timer(0.2), "timeout")
	emitter.emitting = false

func start_heal_particle():
	$Armature/Skeleton/head/heal_particles.emitting = true
	yield(get_tree().create_timer(1.0), "timeout")
	$Armature/Skeleton/head/heal_particles.emitting = false

func start_roll_particles():
	pass
	#start_kick_left(false)
	#start_kick_right(false)

func play_pickup_sound(item):
	var part = "item_sound"+str(item_sound)
	item_sound = item_sound != 1
	if item is AudioStream:
		var sound = audio.get_node(part)
		sound.stream = item
		sound.play()
	else:
		if !item in sounds:
			item = "_pickup"
		play_sound(part, item, true)

func lock():
	anim.process_mode = AnimationTree.ANIMATION_PROCESS_IDLE

func unlock():
	anim.process_mode = AnimationTree.ANIMATION_PROCESS_PHYSICS

func hold_gun(blend: float):
	anim["parameters/GunHold/blend_amount"] = blend
	if blend:
		player.show_ammo()
	else:
		player.hide_ammo()

func weapons_locked():
	return player.is_locked()

func track_weapon(weapon: String):
	player.track_weapon(weapon)

func blend_gun(active: float):
	gun_tween.stop_all()
	gun_tween.interpolate_property(
		anim, "parameters/Gun/blend_amount",
		anim["parameters/Gun/blend_amount"], active*0.9,
		0.1, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	gun_tween.start()

func target_aim(target_dir: Vector3) -> Vector2:
	var aim_basis:Basis = aim_reference.global_transform.basis
	var up := aim_basis.y.normalized()
	if !up.is_normalized():
		return Vector2.ZERO
	var y_cur: Vector3 = aim_basis.z
	var y_tar: Vector3 = target_dir.slide(up)
	var y_axis: Vector3 = y_cur.cross(y_tar).normalized()
	var y_angle: float = y_cur.angle_to(y_tar)
	
	return Vector2(
		-y_angle/(PI/2)*sign(aim_basis.y.dot(y_axis)),
		target_dir.normalized().y
	)

func aim_gun(dir: Vector3, aiming: bool):
	var aim: Vector2
	if dir == Vector3.ZERO:
		aim = Vector2.ZERO
	else:
		aim = target_aim(dir)
	anim["parameters/Aim/blend_position"] = aim
	camera_rig.set_aiming(aiming)

func get_normal_gun_orientation() -> Vector3:
	var skeleton: Skeleton = $Armature/Skeleton
	var idx : int = skeleton.find_bone("Gun.R")
	var local_bone_transform: Transform = skeleton.get_bone_global_pose_no_override(idx)
	var t : Transform = skeleton.global_transform*local_bone_transform
	return t.basis.y

func start_hover():
	hover_board.show()
	transition_to("Hover")

func hover_lean(input: Vector2, delta: float):
	var old_blend = anim["parameters/WholeBody/Hover/blend_position"]
	var diff :Vector2 = input - old_blend
	var rate := Vector2(min(5*delta, 0.1), min(15*delta, 0.2))
	if input.x*old_blend.x >= 0:
		if abs(input.x) > abs(old_blend.x):
			rate.x = min(15*delta, 0.3)
	else:
		rate.x = min(30*delta, 0.5)
	anim["parameters/WholeBody/Hover/blend_position"] += diff*rate

func stop_hover():
	hover_board.hide()

func play_fire():
	anim["parameters/Fire/active"] = true

func hold_item(node: Spatial):
	held_item = node
	$Armature/Skeleton/handRight/ref.add_child(held_item)
	held_item.transform = Transform.IDENTITY

func release_item() -> Spatial:
	var h = held_item
	if h:
		h.get_parent().remove_child(h)
	held_item = null
	return h
