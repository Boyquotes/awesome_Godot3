extends KinematicBody

export(bool) var positive := true
export(float) var mass := 100.0
var contributing_mass := 0.0

var grav_stun_time := 0
onready var balance = get_parent()
onready var timer = $Timer

func _ready():
	add_mass(mass)

func gravity_stun(_d):
	add_mass(-mass)
	timer.start(Global.gravity_stun_time)

func _on_timeout():
	print("TIMEOUT")
	add_mass(-contributing_mass + mass)

func add_mass(m):
	contributing_mass += m
	if positive:
		balance.mass_one += m
	else:
		balance.mass_two += m
	balance.activate()
