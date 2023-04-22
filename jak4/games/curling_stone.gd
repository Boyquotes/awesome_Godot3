extends RigidBody

export(float) var damp := 0.005
export(float) var damage_impulse := 40.0
export(float) var collision_damp := 0.1
export(bool) var use_gravity := true
export(float) var rotate_speed := 0.1
export(float) var reset_plane := -100.0

onready var pos := transform.origin
onready var ray_cast := $RayCast
onready var desired_float:float = ray_cast.cast_to.length()

var max_float_force := mass*10.0
var velocity_correction := -mass*0.5

func _ready():
	var _x = Global.get_player().connect("died", self, "reset")

func take_damage(damage, dir, _source, _tag := ""):
	dir.y = 0
	apply_central_impulse(damage*dir*damage_impulse)

func _physics_process(delta):
	if transform.origin.y < reset_plane:
		reset()
	if ray_cast.is_colliding():
		var dist:float = (ray_cast.get_collision_point()-ray_cast.global_transform.origin).length_squared()
		var f := (dist - desired_float*desired_float)/(desired_float*desired_float)
		add_central_force(ray_cast.cast_to.normalized()*f*max_float_force + Vector3.UP*linear_velocity.y*velocity_correction)

func reset():
	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	transform.origin = pos
