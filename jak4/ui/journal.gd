extends Control

export(StyleBox) var hrule_style

onready var list := $panel/hbox/items/list
onready var subject_name := $panel/hbox/notes/header/text/name
onready var subject_image := $panel/hbox/notes/header/TextureRect
onready var subject_notes := $panel/hbox/notes/header/text/notes
onready var subject_headline := $panel/hbox/notes/header/text
onready var notes := $panel/hbox/notes
onready var task_notes := $panel/hbox/notes/notes/list

const image_path := "res://ui/notes/%s/%s.png"
var show_background := true

var starting_item : Node
var temp_notes: Array

enum NoteType {
	People,
	Places,
	ActiveTasks,
	CompletedTasks
}

func _init():
	temp_notes = []

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_active(is_visible_in_tree())

func set_active(active):
	if active:
		notes.hide()
		starting_item = null
		clear(list)
		populate_list(NoteType.People)
		populate_list(NoteType.Places)
		populate_list(NoteType.ActiveTasks)
		populate_list(NoteType.CompletedTasks)
		if starting_item:
			call_deferred("show_notes")

func get_image(category: String, subject: String) -> Texture:
	# Competed tasks have the same image as active
	if category == "completed":
		category = "tasks"
	var path: String = (image_path % [category, subject]).to_lower()
	if ResourceLoader.exists(path):
		var r = ResourceLoader.load(path) as Texture
		if r:
			return r
	return null
	
func populate_list(type: int):
	var category := ""
	var ids := []
	match type:
		NoteType.People:
			category = "people"
			ids = Global.get_notes(category).keys()
		NoteType.Places:
			category = "places"
			ids = Global.get_notes(category).keys()
		NoteType.ActiveTasks:
			category = "tasks"
			for t in Global.game_state.active_tasks:
				ids.append(t.id)
		NoteType.CompletedTasks:
			category = "completed"
			for t in Global.game_state.completed_tasks:
				ids.append(t.id)
	if ids.empty():
		return
	
	var label := Label.new()
	label.text = category.capitalize()
	list.add_child(label)
	
	for key in ids:
		var button := Button.new()
		button.text = key.capitalize()
		list.add_child(button)
		if !starting_item:
			starting_item = button
		
		var _x = button.connect("focus_entered", self, "_on_subject_focused", [type, key])
	
	var panel := Panel.new()
	panel.rect_min_size.y = 20
	panel.add_stylebox_override("panel", hrule_style)
	list.add_child(panel)

func _on_subject_focused(type: int, subject: String):
	var category := ""
	var t: Array
	var n : Array
	match type:
		NoteType.People:
			category = "people"
			t = Global.task_notes_by_person(subject)
			n = Global.get_notes(category, subject)
		NoteType.Places:
			category = "places"
			t = Global.task_notes_by_place(subject)
			n = Global.get_notes(category, subject)
		NoteType.ActiveTasks:
			category = "tasks"
			var task = Global.find_task(subject, true)
			if task is Task:
				for i in range(task.general_notes.size()):
					n.append(task.general_notes[task.general_notes.size() - 1 - i])
				t.append_array(task.people_notes.values())
				t.append_array(task.place_notes.values())
		NoteType.CompletedTasks:
			var task = Global.find_task(subject, false)
			category = "tasks"
			if task is Task:
				n = task.general_notes
				t.append_array(task.people_notes.values())
				t.append_array(task.place_notes.values())
	subject_name.text = subject.capitalize()
	subject_image.texture = get_image(category, subject)
	
	clear(subject_notes)
	clear(task_notes)
	
	for note in n:
		var l := Label.new()
		l.autowrap = true
		l.text = note
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		subject_notes.add_child(l)

	for note in t:
		var l := Label.new()
		l.autowrap = true
		l.text = note
		l.size_flags_horizontal = SIZE_EXPAND_FILL
		task_notes.add_child(l)
		

func show_notes():
	notes.show()
	if starting_item:
		starting_item.grab_focus()

func clear(node: Node):
	for c in node.get_children():
		c.queue_free()
