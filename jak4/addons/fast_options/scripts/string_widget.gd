extends Control

signal changed(opt_name, value)

var option_name:String

func _ready():
	for c in get_children():
		c.focus_neighbour_left = c.get_path()

func set_option_hint(option:Dictionary):
	option_name = option.name
	$name.text = option_name.capitalize()
	var hint: String = option.hint_string
	if hint != "" and hint != null:
		var values = hint.split(",", false)
		for val in values:
			$value.add_item(val)

func set_option_value(val:String):
	var idx = $value.items.find(val)
	if idx != -1:
		$value.select(idx)

func grab_focus():
	$value.grab_focus()

func _on_value_item_selected(ID):
	print("changed:", ID)
	emit_signal("changed", option_name, $value.get_item_text(ID))
