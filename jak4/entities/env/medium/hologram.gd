tool
extends MeshInstance

export(bool) var real_object_visible := true setget set_real_visible
export(Material) var invisible_material: Material
export(Material) var hologram_material: Material

func _ready():
	material_overlay = hologram_material
	for c in get_children():
		c.material_overlay = hologram_material

func set_real_visible(v):
	real_object_visible = v
	if !is_inside_tree():
		return
	else:
		if !real_object_visible:
			material_override = invisible_material
		else:
			material_override = null
		for c in get_children():
			if c is GeometryInstance:
				c.material_override = material_override
