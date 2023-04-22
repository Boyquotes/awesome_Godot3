tool
extends Control

var active_source := ""
onready var text_window : TextEdit = $VBoxContainer/PanelContainer2/HBoxContainer/TextEdit
onready var active_view : Label = $VBoxContainer/PanelContainer/HBoxContainer/Label

enum FileOp {
	Open,
	Save,
	SaveAs,
	New
}

func _ready():
	text_window.add_color_region(">", "\n", Color.antiquewhite, true)
	text_window.add_color_region("*", "\n", Color.gray, true)
	text_window.add_color_region(":", "\n", Color.orange, true)
	text_window.add_color_region("[", "]", Color.lightcoral)
	text_window.add_color_region("{", "}", Color.aquamarine)
	var mp:PopupMenu = $VBoxContainer/PanelContainer/HBoxContainer/MenuButton.get_popup()
	var _x = mp.connect("id_pressed", self, "_on_file_pressed")

func _on_file_pressed(id: int):
	match id:
		FileOp.Open:
			yield(select_file(FileDialog.MODE_OPEN_FILE), "completed")
			open(active_source)
		FileOp.Save:
			save()
		FileOp.SaveAs:
			yield(select_file(), "completed")
			save()
		FileOp.New:
			_set_active_source("")
			text_window.text = ""

func open(src_path: String):
	_set_active_source(src_path)
	var in_file := File.new()
	
	var err := in_file.open(src_path, File.READ)
	if err != OK:
		print_debug("NP Dialog failed to edit %s, error code %d" 
			% [src_path, err])
		return err
	
	text_window.text = in_file.get_as_text()
	in_file.close()

func save(auto := false):
	if active_source == "":
		if auto:
			return
		yield(select_file(), "completed")
	write_to(active_source)

func _set_active_source(source):
	active_source = source
	active_view.text = "<new file>" if source == "" else source

func select_file(mode := FileDialog.MODE_SAVE_FILE):
	var fd :FileDialog = $FileDialog
	fd.mode = mode
	fd.popup_centered()
	_set_active_source(yield(fd, "file_selected"))

func write_to(source):
	print("Writing to: ", source)
	var out_file := File.new()
	var err := out_file.open(source, File.WRITE)
	if err != OK:
		print_debug("NP Dialog: failed to save to %s, error code %d" 
			% [source, err])
		return err
	out_file.store_string(text_window.text)
