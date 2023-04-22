extends Weapon
class_name WaveShot

const MAX_RADIUS = 8
const MIN_RADIUS = 1
const RADIUS_SEC = 4

const MAX_RECOIL = 16
const MIN_RECOIL = 5
const RECOIL_SEC = 8

var charging := false
var charging_time := 0.0
var time_since_fired := INF
var recoil: Vector3

var bubble_pool : Array
onready var bubble := $bubble
onready var scene = get_tree().current_scene

var speed = 1.0 setget set_speed

func _init():
	charge_fire = true
	infinite_ammo = false
	time_firing = 0.3
	locks_on = false

func _ready():
	bubble_pool = [bubble]
	remove_child(bubble)
	set_speed(speed)

func _process(delta):
	$Particles.emitting = charging
	time_since_fired += delta
	if charging:
		charging_time += delta*speed

func set_speed(s):
	speed = s
	$ChargeSound.pitch_scale = speed
	$AnimationPlayer.playback_speed = speed

func can_charge():
	return time_since_fired > time_firing

func charge():
	if !can_charge() or Global.count("wave_shot") <= 0:
		return
	$ChargeSound.play()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("Charging")
	$AnimationPlayer.queue("MaxCharge-loop")
	charging_time = 0.0
	charging = true

func fire():
	var _x = Global.remove_item("wave_shot")
	$FireSound.play()
	$ChargeSound.stop()
	$AnimationPlayer.stop()
	$AnimationPlayer.clear_queue()
	$AnimationPlayer.play("Fire")
	time_since_fired = 0
	$Particles.emitting = false
	var new_bubble: Spatial
	var created := false
	if bubble_pool.empty():
		new_bubble = bubble.duplicate()
		created = true
	else:
		new_bubble = bubble_pool.pop_back()
	scene.add_child(new_bubble)
	if created:
		new_bubble.make_unique()
	new_bubble.global_transform.origin = global_transform.origin
	
	var r = clamp(charging_time*RADIUS_SEC, MIN_RADIUS, MAX_RADIUS)
	recoil = Vector3.UP*clamp(charging_time*RECOIL_SEC, MIN_RECOIL, MAX_RECOIL)
	new_bubble.fire(r, time_firing)
	
	charging = false
	return true

func stow():
	$ChargeSound.stop()
	$AnimationPlayer.stop()
	$Particles.emitting = false
	charging = false
	.stow()

func _on_bubble_remove(node):
	scene.remove_child(node)
	bubble_pool.append(node)

func combo_fire():
	# uh
	charging_time = 10.0
	return fire()
