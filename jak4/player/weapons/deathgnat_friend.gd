extends KinematicBody

const FOLLOW_RADIUS_MIN := 2.0
const FOLLOW_RADIUS_MAX := 2.5
const DESIRED_HEIGHT := 2.0
const ACCELERATION := 25.0
const SPEED := 25.0

export(PackedScene) var projectile: PackedScene 
export(float) var cooldown := 2.0
export(float) var attack_damage := 5.0
export(float) var orb_speed := 10.0
export(float) var orb_seeking := 2.0

var velocity := Vector3.ZERO
var target : KinematicEnemy
var time_fired := 0.0

onready var player := Global.get_player()
onready var awareness := $awareness

func _ready():
	$AnimationPlayer.play("Idle-loop")

func _physics_process(delta):
	var dir:Vector3 = player.global_transform.origin - global_transform.origin
	var speed = SPEED
	var change_y := dir.y
	dir.y = 0
	var l = dir.length()
	if l < FOLLOW_RADIUS_MIN:
		dir = -dir
	elif l < FOLLOW_RADIUS_MAX:
		speed = player.velocity.length()
		if speed != 0:
			dir = player.velocity/speed
		else:
			dir = Vector3.ZERO
	
	dir.y = change_y + DESIRED_HEIGHT
	dir /= 5
	if dir.length() > 1:
		dir = dir.normalized()
	velocity = velocity.move_toward(speed*dir, delta*ACCELERATION)
	velocity = move_and_slide(velocity)

func _process(delta):
	var vis_target : Vector3
	if !target:
		var closest_distance := INF
		for b in awareness.get_overlapping_bodies():
			if !b is KinematicEnemy:
				continue
			var d = (b.global_transform.origin - global_transform.origin).length_squared()
			if d <= closest_distance:
				closest_distance = d
				target = b
	elif target.is_dead():
		target = null
	if target:
		vis_target = target.global_transform.origin
		time_fired += delta
		if time_fired >= cooldown:
			fire_orb()
			time_fired = 0
	else:
		vis_target = player.global_transform.origin
	vis_target.y = global_transform.origin.y
	global_transform = global_transform.looking_at(vis_target, Vector3.UP)

func fire_orb():
	var orb = projectile.instance()
	get_parent().add_child(orb)
	orb.damage = attack_damage
	orb.speed = orb_speed
	orb.turn_speed = orb_seeking
	orb.global_transform.origin = $orb_spawner.global_transform.origin
	orb.fire(target, Vector3.ZERO)
