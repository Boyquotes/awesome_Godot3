extends Control

var level := 0
onready var ui := get_parent().get_parent().get_parent()
var show_background = true

func _ready():
	hide()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_active(is_visible_in_tree())

func set_active(active):
	if active:
		Settings.load_settings()
		set_level(0)
	else:
		Settings.save_settings()

func set_level(l: int):
	if l < 0:
		l = 0
	if l > 2:
		l = 2
	match l:
		0:
			for c in $foreground/main_menu.get_children():
				if c is Control:
					c.focus_mode = Control.FOCUS_ALL
			$foreground/main_menu/AnimationPlayer.play("fade_in")
			if level == 1:
				$foreground/main_menu/options.grab_focus()
			else:
				$foreground/main_menu/resume.grab_focus()
			
				
			$foreground/mainOptions.hide()
			
			$foreground/audioOptions.hide()
			$foreground/controlOptions.hide()
			$foreground/displayOptions.hide()
			$foreground/graphicsOptions.hide()
		1:
			if level == 0:
				for c in $foreground/main_menu.get_children():
					if c is Control:
						c.focus_mode = Control.FOCUS_NONE
				$foreground/main_menu/AnimationPlayer.play("fade_out")
					
			for c in $foreground/mainOptions.get_children():
				if c is Control:
					c.focus_mode = Control.FOCUS_ALL
					
			$foreground/mainOptions.show()
			$foreground/mainOptions/AnimationPlayer.play("fade_in")
			$foreground/mainOptions/audio.grab_focus()
			
			$foreground/audioOptions.hide()
			$foreground/controlOptions.hide()
			$foreground/displayOptions.hide()
			$foreground/graphicsOptions.hide()
		2:
					
			if level == 0:
				$foreground/main_menu/AnimationPlayer.play("fade_out")
				for c in $foreground/main_menu.get_children():
					if c is Control:
						c.focus_mode = Control.FOCUS_NONE
			elif level == 1:
				for c in $foreground/mainOptions.get_children():
					if c is Control:
						c.focus_mode = Control.FOCUS_NONE
				$foreground/mainOptions/AnimationPlayer.play("fade_out")
	level = l

func _on_resume_pressed():
	ui.unpause()

func _on_options_pressed():
	set_level(1)

func _on_reload_pressed():
	Global.get_player().respawn()
	ui.unpause()

func _on_quit_pressed():
	Global.save_sync()
	get_tree().quit()

func _on_audio_pressed():
	set_level(2)
	$foreground/audioOptions.show()
	$foreground/controlOptions.hide()
	$foreground/displayOptions.hide()
	$foreground/graphicsOptions.hide()
	$foreground/audioOptions.grab_focus()

func _on_controls_pressed():
	set_level(2)
	$foreground/audioOptions.hide()
	$foreground/controlOptions.show()
	$foreground/displayOptions.hide()
	$foreground/graphicsOptions.hide()
	$foreground/controlOptions.grab_focus()
	
func _on_display_pressed():
	set_level(2)
	$foreground/audioOptions.hide()
	$foreground/controlOptions.hide()
	$foreground/displayOptions.show()
	$foreground/graphicsOptions.hide()
	$foreground/displayOptions.grab_focus()

func _on_graphics_pressed():
	set_level(2)
	$foreground/audioOptions.hide()
	$foreground/controlOptions.hide()
	$foreground/displayOptions.hide()
	$foreground/graphicsOptions.show()
	$foreground/graphicsOptions.grab_focus()

func _on_displayOptions_ui_redraw():
	get_tree().call_group("ui_settings_custom", "ui_settings_apply")

func _on_back_pressed():
	set_level(level - 1)
