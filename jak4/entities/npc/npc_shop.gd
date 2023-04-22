extends NPC
class_name NPC_Shop

export(Resource) var inventory_data

func _init():
	visual_name = "Shop Keeper"

func _ready():
	if inventory_data:
		if "persistent" in inventory_data:
			for pitem in inventory_data.persistent:
				pitem["C"] -= Global.stat(item_bought_stat(pitem["I"]))

func get_inventory() -> Dictionary:
	return inventory_data

func mark_sold(id: String):
	var bought: Dictionary = item_data(inventory_data.persistent, id)
	if !bought.empty():
		var _x = Global.add_stat(item_bought_stat(id))
	else:
		bought = item_data(inventory_data.temporary, id)
	if bought.empty():
		print_debug("BUG: marking sale of non-existent ", id)
	else:
		bought["C"] -= 1

func item_bought_stat(id) -> String:
	var short_id = friendly_id if friendly_id != "" else name
	var s =  "bought/"+short_id+"/"+id
	return s

func item_data(array: Array, id: String) -> Dictionary:
	for c in array:
		if c["I"] == id:
			return c
	return {}
