extends Resource
class_name Task

export(String) var id
# Dictionary (string place -> String note)
export(Dictionary) var place_notes
# Dictionary (string place -> String note)
export(Dictionary) var people_notes
# Chronological notes
export(Array, String) var general_notes: Array

func _init(p_id := ""):
	id = p_id
	resource_name = "Task"
	general_notes = []
	place_notes = {}
	people_notes = {}
