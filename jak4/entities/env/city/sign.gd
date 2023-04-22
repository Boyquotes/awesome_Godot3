tool
extends Spatial

export(Texture) var texture : Texture setget set_texture
export(NodePath) var sign_mesh : NodePath

onready var mesh: MeshInstance = get_node(sign_mesh)

func _ready():
	set_texture(texture)

func set_texture(val: Texture):
	texture = val
	if mesh:
		var mat: ShaderMaterial = mesh.get_surface_material(1)
		mat.set_shader_param("main_texture", val)
