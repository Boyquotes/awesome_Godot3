extends Resource
class_name Story

export(String) var category := "people"
export(String) var subject := ""
export(String, MULTILINE) var text := ""

func _init():
	resource_name = "Story"
