extends Object
class_name DisplaySettings

signal ui_redraw

var theme:Theme = load("res://ui/default_theme.tres")

#warning-ignore:unused_class_variable
export(bool) var full_screen setget set_fullscreen, get_fullscreen
#warning-ignore:unused_class_variable
export(bool) var vsync setget set_vsync, get_vsync
export (int, 8, 48) var text_size setget set_textsize, get_textsize
export (Color) var text_color setget set_text_color, get_text_color

func get_name() -> String:
	return "Display"

func set_fullscreen(val: bool):
	full_screen = val
	OS.window_fullscreen = val

func get_fullscreen() -> bool:
	full_screen = OS.window_fullscreen
	return full_screen

func set_vsync(val: bool):
	vsync = val
	OS.vsync_enabled = val

func get_vsync()->bool:
	vsync = OS.vsync_enabled
	return vsync

func get_textsize():
	text_size = theme.default_font.size
	return text_size

func set_textsize(val):
	text_size = val
	theme.default_font.size = val
	emit_signal("ui_redraw")

func get_text_color()->Color:
	text_color = theme.get_color("font_color", "Label")
	return text_color

func set_text_color(val:Color):
	#assert(val != Color.black)
	text_color = val
	theme.set_color("font_color", "Label", text_color)
	theme.set_color("font_color", "Button", text_color)
	theme.set_color("font_color", "OptionButton", text_color)
	theme.set_color("font_color_fg", "Tabs", text_color)
	theme.set_color("font_color_fg", "TabContainer", text_color)
	emit_signal("ui_redraw")
