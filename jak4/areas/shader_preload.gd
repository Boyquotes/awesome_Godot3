extends Spatial

var flags = 0
var max_flags = 128

var loader : ResourceInteractiveLoader
var done_loading := false

func _enter_tree():
	loader = ResourceLoader.load_interactive("res://areas/world.tscn")

func _process(_delta):
	$"lights/glass-furnace".light_enabled = flags & 1
	$lights/OmniLight.visible = flags & 2
	$lights/SpotLight.visible = flags & 4
	$lights/ReflectionProbe.interior_enable = flags & 8
	$lights/ReflectionProbe.visible = flags & 16
	$lights/light_wall.light_enabled = flags & 32
	$lights/sun.visible = flags & 64
	flags += 1
	
	if flags >= max_flags:
		if !done_loading:
			var _x = loader.wait()
		var _x = get_tree().change_scene_to(loader.get_resource())
	elif !done_loading:
		done_loading = loader.poll() == ERR_FILE_EOF
