extends Panel

var show_background := true

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_active(is_visible_in_tree())

func set_active(a):
	if a:
		$buttons/new_game.grab_focus()

func set_background_texture(t: Texture):
	$TextureRect.texture = t
	
func _on_new_game_pressed():
	$new_game.popup_centered()

func _on_new_game_confirmed():
	Global.reset_game()
