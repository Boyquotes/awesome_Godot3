tool
extends AnimationPlayer

const search_path := "res://_glb/characters/jackie/anim"

func _enter_tree():
	if Engine.editor_hint:
		var dir = Directory.new()
		var err = dir.open(search_path)
		if err != OK:
			print_debug("Failed to open player animations. Code: ", err)
			return
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".anim"):
				var anim_name = file_name.replace(".anim", "")
				if !has_animation(anim_name):
					var full_path = dir.get_current_dir() + "/" + file_name
					var _x = add_animation(anim_name, load(full_path))
					print("Added ", anim_name)
			file_name = dir.get_next()
		dir.list_dir_end()
