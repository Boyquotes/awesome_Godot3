extends Spatial

export(NodePath) var target_node
export(float, 0.01, 1.0, 0.01) var max_distance := 0.02
export(float, 0.00, 1.00, 0.001) var damp := 0.2
export(float, 0.1, 25.0) var acceleration := 5.0
export(float, 0.0, 1.0) var player_velocity_match := 0.75

const max_rel_velocity := 0.0

onready var target := get_node(target_node)
onready var player := Global.get_player()

var velocity := Vector3.ZERO
var player_vel := Vector3.ZERO
var max_velocity := 30.0

func _ready():
	global_transform = target.global_transform
	if !Global.get_player():
		set_physics_process(false)

func _physics_process(delta):
	var md2 := max_distance*max_distance
	var rel:Vector3 = target.global_transform.origin - global_transform.origin
	var d:float = rel.length_squared()
	
	var added_velocity := acceleration*rel*sqrt(md2/(clamp(md2 - d, 0.00005, md2)))
	velocity += added_velocity
	if velocity.length_squared() > max_velocity*max_velocity:
		velocity = velocity.normalized()*max_velocity
	player_vel = lerp(player_vel, player.velocity, 0.2)
	
	global_transform.origin += delta*(velocity
		+ player_velocity_match*player_vel)
	velocity *= 1.0 - damp
	
	var t :Vector3 = global_transform.origin - target.global_transform.origin
	if t.length_squared() > md2:
		var newt = t.normalized()*max_distance
		global_transform.origin = target.global_transform.origin + newt

