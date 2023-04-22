extends KinematicBody

export(float, 0.1, 10.0) var activation_time := 2.0
export(float, 0.1, 5.0) var pause_time := 1.0
export(float, 0.1, 60.0) var reset_time := 8.0
export(float, 0.1, 50.0) var required_damage := 5.0
export(NodePath) var world_animations

onready var world_anim:AnimationPlayer = get_node(world_animations)
onready var switch_anim:AnimationPlayer = $AnimationPlayer

onready var activation_speed := 1.0/activation_time
onready var reset_speed := -1.0/reset_time

enum State {
	Start,
	End,
	Process
}
var state = State.Start

func set_playback_speed(vel):
	switch_anim.playback_speed = vel
	world_anim.playback_speed = vel

func take_damage(dam, _dir, _source, _tag := ""):
	if dam > required_damage:
		set_playback_speed(activation_speed)
		if !switch_anim.is_playing() and state == State.Start:
			switch_anim.play("rotate")
			world_anim.play("Activate")

func start():
	if switch_anim.playback_speed > 0:
		state = State.Process
	else:
		state = State.Start

func end():
	if switch_anim.playback_speed < 0:
		state = State.Process
	else:
		state = State.End
		$Timer.start(pause_time)

func _on_Timer_timeout():
	if state != State.End:
		return
	set_playback_speed(reset_speed)
	if !switch_anim.is_playing():
		switch_anim.play("rotate")
		world_anim.play("Activate")
		switch_anim.seek(switch_anim.current_animation_length)
		world_anim.seek(world_anim.current_animation_length)
