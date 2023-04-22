extends Spatial

export(Gradient) var palette: Gradient
export(NodePath) var mesh_instance
export(String) var shader_param := "albedo"

onready var mesh = get_node(mesh_instance)

func _ready():
	var color := palette.interpolate(randf())
	
	var mat = mesh.get_surface_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_param(shader_param, color)
	elif mat is SpatialMaterial:
		mat.albedo_color = color
	else:
		print_debug("No material for mesh: ", mesh.get_path())
