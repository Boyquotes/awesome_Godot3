tool
extends EditorScript

const path_f := "res://areas/chunks/%s.tscn"

func _run():
	var scn = get_scene()
	for c in scn.get_children():
		var chunk = path_f % c.name
		if ResourceLoader.exists(chunk):
			var sc: Chunk = load(chunk).instance()
			sc.set_active(false)
			c.add_child(sc)
			sc.get_node("__autogen_preview").queue_free()
			print("Adding ", c.name)

