extends ProgressBar

signal reset
signal sleep

const RESET_TIME := 2.0
const INCREASE := 1.0
const DECREASE := 3.0

export(String) var reset_text := "HOLD TO RESET..."
export(String) var sleep_text := "Going to sleep..."

onready var label := $Label

var sleep := false
var vis_sleep := sleep

func _process(delta):
	if value < 0.01 and sleep != vis_sleep:
		label.text = sleep_text if sleep else reset_text
		vis_sleep = sleep
	var change := 0.0
	if Input.is_action_pressed("reset"):
		change = INCREASE * delta
		show()
	elif sleep and Input.is_action_pressed("mv_crouch"):
		change = INCREASE * delta
		show()
	else:
		change = -DECREASE * delta
	
	value = clamp(value + change, 0, 1)
	if value >= 1:
		if sleep:
			emit_signal("sleep")
		else:
			emit_signal("reset")
		value = 0
	if value == 0:
		hide()
