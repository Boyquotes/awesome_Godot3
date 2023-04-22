extends Resource
class_name ShopInventory

export(Array, Dictionary) var persistent
export(Array, Dictionary) var temporary

func _init():
	resource_name = "ShopInventory"
