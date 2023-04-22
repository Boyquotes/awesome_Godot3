extends Node

const save_path = "user://settings.cfg"

export (Array, Script) var option_scripts
var sub_options: Dictionary
var option_scripts_dict : Dictionary

signal ui_redraw

const USAGE_FLAGS = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR

func _enter_tree():
	sub_options = {}
	for osc in option_scripts:
		var options = osc.new()
		if options is Node:
			add_child(options)
		if osc.has_script_signal("ui_redraw"):
			var res = options.connect("ui_redraw", self, "emit_signal", ["ui_redraw"])
			if res != OK:
				print_debug("Could not connect ui_redraw signal!  Error: ", res)
		sub_options[options.get_name()] = options
		option_scripts_dict[options.get_name()] = osc
	load_settings()

func _exit_tree():
	save_settings()

func load_settings():
	var f:File = File.new()
	if !f.file_exists(save_path):
		print_debug("No settings file: ", save_path)
		return
	var file:ConfigFile = ConfigFile.new()
	var res = file.load(save_path)
	if res != OK:
		print_debug("Failed to load save file: ", save_path,
				 "\nError code: ", res)
		return
	
	for section in file.get_sections():
		if !(section in sub_options):
			print_debug("WARNING: unknown options section: ", section)
			continue
		sub_load_from(sub_options[section], file)

func save_settings():
	var file:ConfigFile = ConfigFile.new()
	for o in sub_options.values():
		file = sub_save_to(o, file)

	var res = file.save(save_path)
	if res != OK:
		print_debug("Failed to save config file with error: ",res)

func sub_load_from(options, file: ConfigFile):
	var section_name = options.get_name()
	if options.has_method("set_option"):
		for property in file.get_section_keys(options.get_name()):
			options.set_option(property, file.get_value(section_name, property))
	else:
		for property in file.get_section_keys(options.get_name()):
			options.set(property, file.get_value(section_name, property))

func sub_save_to(options, file: ConfigFile):
	var section_name = options.get_name()
	for property in options.get_property_list():
		if property.usage & USAGE_FLAGS == USAGE_FLAGS:
			file.set_value(section_name, property.name, options.get(property.name))
	return file
