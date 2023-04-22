extends KinematicBody

export(bool) var active := true
export(float) var max_rotation_speed := 20.0
export(float) var imparted_velocity := 2.0
export(float) var effective_range := 15.0
export(bool) var wide := false

onready var particles = $Particles
onready var prop := $fan_body/propeller
onready var hurtbox := $hurtbox
onready var windbox := $windbox
onready var audio := $AudioStreamPlayer3D
const activate_time := 0.4
const deactivate_time := 3.0

const ACCEL := 2.0
var speed := 0.0
export(float) var audio_scale := 5.0

func _ready():
	set_active(active)
	audio.seek(randf()*audio.stream.get_length())
	if wide:
		$windbox/CollisionShape.shape.radius = 3
	set_range(effective_range)

func _physics_process(delta):
	if Engine.editor_hint:
		return
	audio.unit_size = audio_scale
	windbox.velocity = imparted_velocity
	speed = lerp(speed, max_rotation_speed if active else 0.0, delta*ACCEL)
	prop.rotate_y(speed*delta)
	$blockade/CollisionShape.disabled = !active or TimeManagement.time_slowed

func set_active(a):
	active = a
	hurtbox.active = active
	particles.emitting = active
	windbox.active = active
	
	for c in get_children():
		if c is Light:
			c.light_color = Color.greenyellow if active else Color.crimson
	
	$Tween.remove_all()
	var p: ParticlesMaterial = particles.process_material
	p.initial_velocity = imparted_velocity
	particles.lifetime = effective_range/imparted_velocity
	particles.amount = clamp(effective_range, 8, 30)
	
	if active:
		$Tween.interpolate_property(audio, "unit_db",
			audio.unit_db, 0, 0.1)
		$Tween.interpolate_property(audio, "pitch_scale",
			audio.pitch_scale, 1, activate_time)
	else:
		$Tween.interpolate_property(audio, "unit_db",
			audio.unit_db, 0, 8.0)
		$Tween.interpolate_property(audio, "pitch_scale",
			audio.pitch_scale, .0001, deactivate_time)
	$Tween.start()

func set_range(r):
	effective_range = r
	var height = r
	particles.visibility_aabb.size.y = height + 1
	var position = r/2
	$windbox/CollisionShape.shape.height = height
	$windbox/CollisionShape.transform.origin.y = position
