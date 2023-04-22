extends MeshInstance

func _ready():
	if Global.valid_game_state:
		material_override = Global.game_state.current_coat.generate_material()
