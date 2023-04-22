extends KinematicBody

export(bool) var active := false
export(float) var time_active := 3.0

export(Color) var active_color
export(Color) var inactive_color

onready var timer := $Timer
onready var light := $light

var door: Door

func _ready():
	if has_node("door"):
		door = $door
	set_active(active)

func _on_touched(_body):
	if !door or door.is_playing():
		return
	if active and time_active != 0:
		return
	set_active(!active)

func set_active(a):
	active = a
	door._on_toggled(active)
	if active and time_active != 0:
		timer.start(time_active)
	light.light_color = active_color if active else inactive_color

func _on_timeout():
	set_active(false)
