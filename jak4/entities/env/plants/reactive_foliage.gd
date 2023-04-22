extends Spatial

onready var area := $Area
onready var radius:float = $Area/CollisionShape.shape.radius
onready var anim := $AnimationTree

const press_accel := 100.0
export(float) var damp := 5.0
export(float) var spring := 90.0

var velocity := Vector2.ZERO
var pos := Vector2.ZERO

var active := false

func _ready():
	set_physics_process(false)
	var _x = area.connect("body_entered", self, "_check")
	_x = area.connect("body_exited", self, "_check")

func _check(_body = null):
	set_physics_process((!area.get_overlapping_bodies().empty() or velocity.length_squared() >= 0.001) and active)

func _physics_process(delta):
	var press := Vector2.ZERO
	var bodies: Array = area.get_overlapping_bodies()
	if bodies.size() > 0:
		for b in bodies:
			var diff = b.global_transform.origin - global_transform.origin
			var d2 := Vector2(diff.dot(global_transform.basis.x), diff.dot(-global_transform.basis.z))
			var l = d2.length()
			if l > radius:
				l = radius
			press += d2.normalized()*(1 - l/radius)
		press = press_accel*press/bodies.size()
	elif velocity.length_squared() < 0.001:
		_check()
	
	velocity += (press - spring*pos - damp*velocity)*delta
	
	pos += velocity*delta
	if pos.length_squared() > 1:
		pos = pos.normalized()
		velocity = velocity.slide(pos)
	anim["parameters/blend_position"] = pos

func process_player_distance(p_pos: Vector3):
	active = (p_pos - global_transform.origin).length_squared() <= 64
	if !active:
		velocity = Vector2.ZERO
	_check()
