extends Control

var last_focused :Control

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_active(is_visible_in_tree())

func set_active(a):
	if !a:
		last_focused = get_focus_owner()
	elif is_instance_valid(last_focused):
		last_focused.grab_focus()
	$black.hide()
