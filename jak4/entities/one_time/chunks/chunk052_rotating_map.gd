extends MeshInstance

signal completed
var proper_angle := 270

var tween := Tween.new()

func _ready():
	add_child(tween)
	if Global.has_stat("052/rotating_map"):
		proper_angle = Global.stat("052/rotating_map")
		rotation_degrees.z = proper_angle
		if proper_angle == 0:
			emit_signal("completed")

func clockwise():
	set_angle(proper_angle - 90)

func anticlockwise():
	set_angle(proper_angle + 90)

func flip():
	set_angle(proper_angle + 180)

func is_complete():
	return proper_angle == 0

func set_angle(a):
	if proper_angle == 0:
		return
	var _x = tween.stop_all()
	_x = tween.interpolate_property(
		self, "rotation_degrees:z", 
		proper_angle, a,
		1.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	proper_angle = a % 360
	Global.set_stat("052/rotating_map", proper_angle)
	if proper_angle == 0:
		_x = tween.interpolate_callback(self, 1.0, "emit_signal", "completed")
	_x = tween.start()

func is_upside_down():
	return proper_angle == 180

func should_be_clockwise():
	return proper_angle == 90

func should_be_anticlockwise():
	return proper_angle == 270
