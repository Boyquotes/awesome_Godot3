extends Weapon

var recharge_speed := 1.0
var drain_speed := 1.0

var percent := 100.0
const MIN_PERCENT_FIRE := 24.0
const INSTANT_FIRE_DRAIN := 10.0
const DRAIN := 6.0
const REGAIN := 8.0

onready var custom_ui: Label = $custom_ui

func _init():
	time_firing = 0.2
	charge_fire = false
	infinite_ammo = true
	locks_on = false

func _ready():
	custom_ui.get_parent().remove_child(custom_ui)

func _process(delta):
	if TimeManagement.time_slowed:
		percent = max(0.0, percent - drain_speed*DRAIN*delta)
		if percent == 0:
			TimeManagement.resume()
	else:
		percent = min(100.0, percent + recharge_speed*REGAIN*delta)
	custom_ui.text = "%d%%" % round(percent)
	var low := percent <= MIN_PERCENT_FIRE
	if TimeManagement.time_slowed:
		custom_ui.modulate = Color.aqua if !low else Color.crimson
	else:
		custom_ui.modulate = Color.white if !low else Color.red

func fire():
	if TimeManagement.time_slowed:
		TimeManagement.resume()
	elif percent <= MIN_PERCENT_FIRE:
		return false
	else:
		percent -= INSTANT_FIRE_DRAIN
		TimeManagement.slow_time()
	return true

func stow():
	hide()

func combo_fire():
	return fire()
