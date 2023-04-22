extends ColorRect

signal time_scale_changed(new_rate)

const slow_time_rate := 0.25
var time_slowed := false

func slow_time():
	time_slowed = true
	$AnimationPlayer.play("Slow")
	Engine.time_scale = slow_time_rate
	AudioServer.global_rate_scale = 1.0/slow_time_rate
	emit_signal("time_scale_changed", Engine.time_scale)

func resume():
	time_slowed = false
	$AnimationPlayer.play("Resume")
	Engine.time_scale = 1.0
	AudioServer.global_rate_scale = 1.0
	emit_signal("time_scale_changed", Engine.time_scale)
