extends MeshInstance

export(String) var combination := "XYZ"
export(bool) var persistent := true
var open := false
var working_set := ""

func _ready():
	if persistent and Global.is_picked(get_path()):
		open = true

func reset():
	working_set = ""

func add_digit(character):
	working_set += character

func unlock() -> bool:
	if working_set == combination:
		open = true
		if persistent:
			Global.mark_picked(get_path())
		return true
	else:
		return false
