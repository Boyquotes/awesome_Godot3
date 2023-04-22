extends HBoxContainer

signal changed(opt_name, value)

var option_name:String

func _ready():
	for c in get_children():
		c.focus_neighbour_left = c.get_path()

func set_option_hint(option:Dictionary):
	if option.hint == PROPERTY_HINT_RANGE:
		var hint:PoolStringArray = option.hint_string.split(",")
		$value/slider.min_value = float(hint[0])
		$value/slider.max_value = float(hint[1])
		if hint.size() == 3:
			$value/slider.step = float(hint[2])
	option_name = option.name
	$name.text = option_name.capitalize()

func set_option_value(val:float):
	$value/label.text = str(val)
	$value/slider.value = val

func grab_focus():
	$value/slider.grab_focus()

func _on_value_changed(value):
	$value/label.text = str(value)
	emit_signal("changed", option_name, value)
