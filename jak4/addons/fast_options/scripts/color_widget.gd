extends HBoxContainer

signal changed(opt_name, value)

var option_name:String

func _ready():
	for c in get_children():
		c.focus_neighbour_left = c.get_path()

func set_option_hint(option:Dictionary):
	option_name = option.name
	$name.text = option_name.capitalize()

func set_option_value(val:Color):
	#assert(val != Color.black)
	$value/rgb/redSlider.value = val.r
	$value/rgb/greenSlider.value = val.g
	$value/rgb/blueSlider.value = val.b
	$value/preview.color = val

func grab_focus():
	$value/rgb/redSlider.grab_focus()

func _on_color_changed(_val):
	var c: Color = Color(
		$value/rgb/redSlider.value,
		$value/rgb/greenSlider.value,
		$value/rgb/blueSlider.value)
	$value/preview.color = c
	emit_signal("changed", option_name, c)
