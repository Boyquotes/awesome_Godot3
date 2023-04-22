extends MeshInstance

export(Array, Texture) var textures : Array
export(String) var shader_param := "main_texture"

func _init():
	textures = []

func _ready():
	if textures.empty():
		return
	var i = abs(int(hash(get_path()) + 90*global_transform.origin.z + global_transform.origin.y))
	var tex = textures[i % textures.size()]
	var s : ShaderMaterial = get_surface_material(0)
	if s:
		s.set_shader_param(shader_param, tex)
