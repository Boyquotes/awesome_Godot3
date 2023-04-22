extends Node
class_name Door

signal opened
signal closed
signal toggled(value)

export(int) var required_power := 1
# Only for triggering doors through events persistently
export(String) var tracked_stat = ""
export(bool) var generate_stat = false
export(bool) var open := false
export(bool) var deactivate_upon_death := false
export(bool) var randomize_speed := false
export(float, 0.1, 4.0) var min_speed := 0.8
export(float, 0.1, 4.0) var max_speed := 1.2

var open_stat := ""

var power := 0
var anim

func _ready():
	if has_node("AnimationPlayer"):
		anim = $AnimationPlayer
	elif has_method("play") and has_method("play_backwards") and has_method("advance"):
		anim = self
	else:
		print_debug("Door %s has no animation node!" % get_path())
	if anim and randomize_speed:
		anim.playback_speed = rand_range(min_speed, max_speed)
	if !is_in_group("dynamic"):
		add_to_group("dynamic")
	if generate_stat:
		tracked_stat = Global.node_stat(self)
	if tracked_stat != "":
		open_stat = "door/" + tracked_stat
		var stat_power = Global.stat(tracked_stat)
		add_power(stat_power, true)
		var _x = Global.connect("stat_changed", self, "_on_stat_changed")
	if open:
		open = false
		add_power(required_power, true)
	else:
		if anim and anim.has_animation("Deactivate"):
			anim.play("Deactivate")
			anim.advance(anim.current_animation_length)
	if deactivate_upon_death:
		var _x = Global.get_player().connect("died", self, "clear_power", [true])
	assert(anim != null, get_path())

func _on_stat_changed(stat, value):
	if stat == tracked_stat:
		power = 0
		add_power(value)

func _on_signal(_arg):
	add_power()

func _on_activated():
	add_power()

func _on_deactivated():
	add_power(-1)

func _on_toggled(active, instant := false):
	add_power(1 if active else -1, instant)

func clear_power(instant := false):
	add_power(-power, instant)

func add_power(amount:= 1, instant := false):
	power += amount
	if power <= 0:
		# Dumb bug I introduced
		power = 0
	var should_open := power >= required_power
	if open_stat != "":
		Global.set_stat(open_stat, should_open)
	
	if should_open and !open:
		if anim.has_animation("Activate"):
			anim.play("Activate")
			if instant:
				anim.advance(anim.current_animation_length)
		else:
			anim.play_backwards("Deactivate")
			if instant:
				anim.seek(0)
		emit_signal("opened")
		emit_signal("toggled", true)
	elif !should_open and open:
		if anim.has_animation("Deactivate"):
			anim.play("Deactivate")
			if instant:
				anim.advance(anim.current_animation_length)
		else:
			anim.play_backwards("Activate")
			if instant:
				anim.seek(0)
		emit_signal("closed")
		emit_signal("toggled", false)
	open = should_open
