extends Spatial

export(bool) var active := true

var spin_speed: float = 0.0
const activate_time := 0.4
const deactivate_time := 3.0

onready var audio := $AudioStreamPlayer3D

func _ready():
	if audio.playing and audio.unit_db < -70:
		audio.stop()
	elif !audio.playing and audio.unit_db > -65:
		audio.play()
	set_active(active)

func _process(delta):
	$drill.rotate_y(spin_speed*delta)

func set_active(a: bool):
	active = a
	$hurtbox/CollisionShape.disabled = !active
	
	$Tween.remove_all()
	
	if active:
		$Tween.interpolate_property(self, "spin_speed", 
			spin_speed, 30, activate_time, Tween.TRANS_CUBIC, Tween.EASE_IN)
		$Tween.interpolate_property(audio, "unit_db",
			audio.unit_db, 0, 0.1)
		$Tween.interpolate_property(audio, "pitch_scale",
			audio.pitch_scale, 1, activate_time)
	else:
		$Tween.interpolate_property(self, "spin_speed", 
			spin_speed, 0, deactivate_time, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		$Tween.interpolate_property(audio, "unit_db",
			audio.unit_db, 0, 8.0)
		$Tween.interpolate_property(audio, "pitch_scale",
			audio.pitch_scale, .0001, deactivate_time)
	$Tween.start()

func _on_toggled(a: bool):
	set_active(a)
