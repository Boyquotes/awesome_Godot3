extends Spatial

signal activated
signal toggled(on)
signal insta_toggled(on)
signal arg_toggled(on, instant)

export(bool) var on := false
export(float) var time_deactivate := 0.0
export(bool) var persistent := false
export(bool) var reset_upon_death := false

onready var anim: AnimationPlayer = $AnimationPlayer
onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
	if persistent and Global.has_stat(get_stat()):
		on = Global.stat(get_stat())
	if reset_upon_death:
		var _x = Global.get_player().connect("died", self, "set_on", [on, true, true])
	set_on(on, true, false, true)

func activate():
	set_on(true)

func deactivate():
	set_on(false, false, true)

func _on_damaged(_damage, dir):
	var switch_on = dir.dot(global_transform.basis.z) > 0.0
	set_on(switch_on)

func set_on(switch_on, instant := false, auto := false, override := false):
	anim.stop()
	if switch_on == on and !override:
		if !instant and !auto:
			if switch_on:
				anim.play("AlreadyOn")
				sound.pitch_scale = 0.7
				sound.play()
			elif !switch_on:
				anim.play("AlreadyOff")
				# Do something better here
				sound.pitch_scale = 0.7
				sound.play()
		return
	
	emit_signal("toggled", switch_on)
	emit_signal("arg_toggled", switch_on, instant)
	if switch_on:
		emit_signal("activated")
		if time_deactivate > 0:
			$deactivate_timer.start(time_deactivate)
	
	if switch_on:
		anim.play("SwitchOn")
	else:
		if auto and anim.has_animation("AutoDeactivate"):
			anim.play("AutoDeactivate")
		else:
			anim.play("SwitchOff")

	if instant:
		anim.seek(anim.current_animation_length)
		emit_signal("insta_toggled", switch_on)
	elif !auto:
		sound.pitch_scale = 1.0
		sound.play()
	else:
		# play a third sound here
		pass
		
	on = switch_on
	if persistent and !instant:
		Global.set_stat(get_stat(), on)

func _on_deactivate_timer_timeout():
	set_on(false, false, true)

func get_stat():
	return str(get_path()) + "/on"
