extends MeshInstance

export(Array, Material) var materials

func pick_material(i: int):
	material_override = materials[i]
