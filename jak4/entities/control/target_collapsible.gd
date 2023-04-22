extends Spatial

export(bool) var open := true
#export(float) var toggle_time := 0.0

onready var anim : AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]

func _ready():
	toggle(open)

func swap():
	toggle(!open)

func toggle(should_open):
	open = should_open
	if open:
		anim.travel("Opened")
	else:
		anim.travel("Closed")
