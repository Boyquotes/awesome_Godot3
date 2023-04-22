extends Resource
class_name Usable

export(Resource) var description
# What item is drained in each use
export(String) var ammo := ""
export(Texture) var icon

var player

func _init():
	resource_name = "Usable"
	player = Global.get_player()

func can_use() -> bool:
	return ammo == "" or Global.count(ammo) > 0

func use():
	if ammo != "":
		var _x = Global.remove_item(ammo)

func equip():
	pass

func unequip():
	pass
