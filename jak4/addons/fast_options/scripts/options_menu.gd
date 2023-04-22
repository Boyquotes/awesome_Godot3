tool
extends Panel

signal ui_redraw

signal cancel
signal apply

const SUBMENU_SCENE = preload("res://addons/fast_options/widgets/submenu.tscn")

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

const USAGE_FLAGS = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR
const save_path = "user://settings.cfg"
export (Array, Script) var option_scripts


var suboptions: Dictionary = {}

onready var tabs = $vbox/tabs

func _enter_tree():
	if get_child_count() == 0:
		var menu:Node = load("res://addons/fast_options/options_menu.tscn").instance()
		for child in menu.get_children():
			add_child(child.duplicate())
		$vbox/buttons/Cancel.connect("pressed", self, "cancel")
		$vbox/buttons/Apply.connect("pressed", self, "apply")
		#menu.queue_free()

func _ready():
	suboptions.clear()
	for script in option_scripts:
		var options:Object = script.new()
		var opt_name:String
		if options is Node:
			add_child(options)
		if options.has_method("get_name"):
			opt_name =  options.get_name()
		else:
			opt_name = options.get_class()
		suboptions[opt_name.to_lower()] = options
		if script.has_script_signal("ui_redraw"):
			var res = options.connect("ui_redraw", self, "_on_ui_redraw")
			if res != OK:
				print_debug("Could not connect ui_redraw signal!  Error: ", res)
	load_settings()
	build_menu()

func build_menu():
	for child in tabs.get_children():
		if child is Control:
			tabs.remove_child(child)
	for opt_name in suboptions.keys():
		var options:Object = suboptions[opt_name]
		var menu = SUBMENU_SCENE.instance()
		if options.has_method("get_name"):
			menu.name =  options.get_name()
		else:
			menu.name = options.get_class()
		tabs.add_child(menu)
		populate_submenu(menu.get_node("scroll/list"), options)

func is_export_var(property)->bool:
	return property.usage & USAGE_FLAGS == USAGE_FLAGS

func populate_submenu(list:Control, options:Object):
	for child in list.get_children():
		if child is Control:
			list.remove_child(child)
	for property in options.get_property_list():
		if is_export_var(property):
			list.add_child(create_widget(options, property))
			list.add_spacer(false)

func create_widget(options:Object, property:Dictionary)->Control:
	var type = property.type
	if options.has_method("get_custom_widgets"):
		var widgets:Dictionary = options.get_custom_widgets()
		if property.name in widgets:
			var widg:Control = widgets[property.name].instance()
			link_widget(options, property, widg)
			return widg
	if WIDGET_SCENES.has(type):
		var widg = WIDGET_SCENES[type].instance();
		link_widget(options, property, widg)
		return widg
	else:
		var value = options.get(property.name)
		if value is Resource and value.resource_name in CUSTOM_WIDGETS:
			var widg = CUSTOM_WIDGETS[value.resource_name].instance()
			link_widget(options, property, widg)
			return widg

		var text = Label.new()
		text.text = "%s: %s (No Widget Available: '%s')" % [
			property.name, 
			type,
			str(options.get(property.name).resource_name)
		]
		return text;

func link_widget(options, property, widget: Control):
	widget.set_option_hint(property)
	widget.set_option_value(options.get(property.name))
	widget.connect("changed", options, "set")

func save_settings():
	var file:ConfigFile = ConfigFile.new()
	for opt_name in suboptions.keys():
		var options:Object = suboptions[opt_name]
		for property in options.get_property_list():
			if property.usage & USAGE_FLAGS == USAGE_FLAGS:
				file.set_value(opt_name, 
					property.name, options.get(property.name))
	var res = file.save(save_path)
	if res != OK:
		print_debug("Failed to save config file with error: ",res)

func load_settings():
	var f:File = File.new()
	if !f.file_exists(save_path):
		print("No settings file: ", save_path)
		return
	var file:ConfigFile = ConfigFile.new()
	var res = file.load(save_path)
	if res != OK:
		print_debug("Failed to load save file: ", save_path,
				 "\nError code: ", res)
		return
	for section in file.get_sections():
		if !suboptions.has(section):
			print_debug("No options for section: ", section)
			continue
		var options:Object = suboptions[section]
		for property in file.get_section_keys(section):
			options.set(property, file.get_value(section, property))

func cancel():
	print("Cancelled changes")
	load_settings()
	build_menu()
	emit_signal("cancel")

func apply():
	print("Settings applied")
	save_settings()
	emit_signal("apply")

func grab_focus():
	$vbox/tabs.get_current_tab_control().grab_focus()

func _on_ui_redraw():
	emit_signal("ui_redraw")

func _on_res_scale(val:float):
	get_tree().set_screen_stretch(
		SceneTree.STRETCH_MODE_VIEWPORT,
		SceneTree.STRETCH_ASPECT_EXPAND,
		OS.window_size/val,
		val)
	print(get_viewport().size)

