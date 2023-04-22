extends Control

signal ui_redraw
signal back_pressed

export(String) var menu_name := ""
export(bool) var with_back_button := true

const WIDGET_SCENES = {
	TYPE_BOOL: preload("res://addons/fast_options/widgets/bool_widget.tscn"),
	TYPE_REAL: preload("res://addons/fast_options/widgets/range_widget.tscn"),
	TYPE_INT: preload("res://addons/fast_options/widgets/range_widget.tscn"),
	TYPE_COLOR: preload("res://addons/fast_options/widgets/color_widget.tscn"),
	TYPE_STRING: preload("res://addons/fast_options/widgets/string_widget.tscn")
}
const CUSTOM_WIDGETS = {
	"AudioChannel": preload("res://addons/fast_options/widgets/volume_widget.tscn")
}

var options: Object

func _ready():
	if menu_name == "":
		menu_name = name
	options = Settings.sub_options[menu_name]
	call_deferred("redraw")

func redraw():
	for child in get_children():
		if child is Control:
			remove_child(child)
	for property in options.get_property_list():
		if is_export_var(property):
			add_child(create_widget(property))
	if with_back_button:
		var back := Button.new()
		back.text = tr("Back")
		add_child(back)
		var _x = back.connect("pressed", self, "emit_signal", ["back_pressed"])

func create_widget(property:Dictionary)->Control:
	var type = property.type
	if options.has_method("get_custom_widgets"):
		var widgets:Dictionary = options.get_custom_widgets()
		if property.name in widgets:
			var widg:Control = widgets[property.name].instance()
			link_widget(property, widg)
			return widg
	if type in WIDGET_SCENES:
		var widg = WIDGET_SCENES[type].instance();
		link_widget(property, widg)
		return widg
	else:
		var value = options.get(property.name)
		if value is Resource and value.resource_name in CUSTOM_WIDGETS:
			var widg = CUSTOM_WIDGETS[value.resource_name].instance()
			link_widget(property, widg)
			return widg

		var text = Label.new()
		text.text = "%s: %s (No Widget Available: '%s')" % [
			property.name, 
			type,
			str(options.get(property.name).resource_name)
		]
		return text;

func link_widget(property, widget: Control):
	widget.set_option_hint(property)
	widget.set_option_value(options.get(property.name))
	if options.has_method("set_option"):
		var _x = widget.connect("changed", options, "set_option")
	else:
		var _x = widget.connect("changed", options, "set")

func is_export_var(property)->bool:
	return property.usage & Settings.USAGE_FLAGS == Settings.USAGE_FLAGS

func _on_ui_redraw():
	emit_signal("ui_redraw")

func grab_focus():
	for c in get_children():
		if c is Control:
			c.grab_focus()
			return
