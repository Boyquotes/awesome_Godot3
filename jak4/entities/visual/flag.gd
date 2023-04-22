tool
extends Spatial

export(Material) var flag_material setget set_material
onready var body := $MeshInstance

func _ready():
	set_material(flag_material)

func set_material(f):
	flag_material = f
	if flag_material and body:
		body.material_override = flag_material
