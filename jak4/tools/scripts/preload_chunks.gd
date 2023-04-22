tool
extends EditorScript

const PATH_CONTENT := "res://areas/chunks/%s.tscn"
const PATH_LOWRES := "res://areas/chunks/%s_lowres.tscn"

func _run():
	var s = get_scene()
	s.preloaded_chunks = {}
	s.preloaded_lowres = {}
	for c in s.get_children():
		if ResourceLoader.exists(PATH_CONTENT % c.name):
			s.preloaded_chunks[c.name] = load(PATH_CONTENT % c.name)
		if ResourceLoader.exists(PATH_LOWRES % c.name):
			s.preloaded_lowres[c.name] = load(PATH_LOWRES % c.name)
