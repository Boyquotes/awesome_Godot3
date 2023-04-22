extends Spatial

export(bool) var on := false

func _ready():
	if on:
		var screen:SpatialMaterial = $phone.get_surface_material(1)
		screen.emission_energy = 1.0
