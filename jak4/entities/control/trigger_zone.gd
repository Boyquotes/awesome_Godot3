extends Area

signal alerted
signal activated_by(body)
signal activated
signal deactivated

export(float) var delay := 0.0
export(float) var min_active_time := 0.0
export(String) var stat := ""

enum State {
	Idle,
	Alerted,
	Active,
	ActiveTimeExceeded
}
var state = State.Idle

var timer: Timer
var active_body: Node

func _ready():
	if has_node("Timer"):
		timer = $Timer
	if delay:
		if !timer:
			print_debug("NO TIMER FOUND: ", get_path())
			return
		timer.one_shot = true
		var _x = timer.connect("timeout", self, "_on_timeout")
	var _x = connect("body_entered", self, "_on_body_entered")
	_x = connect("body_exited", self, "_on_body_exited")

func _on_body_entered(body):
	if stat != "":
		var _x = Global.add_stat(stat)
	print("Body entered: ", body.name, " in ", State.keys()[state])
	match state:
		State.Idle:
			if !delay:
				active_body = body
				activate()
			else:
				alert(body)
		State.Active:
			if timer:
				timer.stop()

func _on_body_exited(body):
	print("Body exited: ", body.name)
	if body != active_body:
		return
	match state:
		State.Alerted, State.ActiveTimeExceeded:
			deactivate()
		State.Active:
			if !min_active_time:
				deactivate()

func _on_timeout():
	print("Timer expired.")
	if state == State.Alerted:
		activate()
	elif state == State.Active:
		if !(active_body in get_overlapping_bodies()):
			deactivate()
		else:
			state = State.ActiveTimeExceeded

func alert(body):
	print("Alerted")
	emit_signal("alerted")
	state = State.Alerted
	active_body = body
	if timer and delay:
		timer.start(delay)

func activate():
	print("Activated")
	emit_signal("activated")
	emit_signal("activated_by", active_body)
	state = State.Active
	if timer and min_active_time:
		timer.start(min_active_time)

func deactivate():
	print("Deactivated")
	emit_signal("deactivated")
	state = State.Idle
