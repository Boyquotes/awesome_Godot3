extends Usable

func _init():
	._init()
	ammo = "flag"
	icon = preload("res://ui/icons/item_flag.png")

func use():
	if !player.best_floor.is_in_group("flag_surface"):
		print("Flag: bad floor")
		player.mesh.hold_item(player.flag.instance())
		player.lock_in_animation("PlaceFlag_Failed")
	else:
		print("Using flag")
		.use()
		player.set_state(player.State.PlaceFlag)

func can_use():
	if !player.best_floor:
		print("Flag: no floor")
		return false
	return .can_use()
