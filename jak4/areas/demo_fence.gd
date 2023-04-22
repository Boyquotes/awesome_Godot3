extends MeshInstance

var mat: ShaderMaterial

func _ready():
	mat = get_surface_material(0)
	mat.set_shader_param("debug", false)

func _process(_delta):
	mat.set_shader_param("world_player", Global.get_player().global_transform.origin)
