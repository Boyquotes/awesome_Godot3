extends Label

export(String) var item_id

func _ready():
	if item_id == "":
		item_id = name
	var _x = Global.connect("item_changed", self, "_on_item_changed")
	_x = connect("visibility_changed", self, "_on_visibility_changed")
	
func _on_item_changed(id, _change, count):
	if id == item_id:
		text = str(count)
	
func _on_visibility_changed():
	if visible:
		text = str(Global.count(item_id))
