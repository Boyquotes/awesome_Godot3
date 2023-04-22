extends Panel

export(PackedScene) var frame_button_template

onready var tree := $log_viewer/menus/stats/func_tree
onready var frames_list := $log_viewer/menus/scroll/frames

func _ready():
	$log_viewer/buttons/file.get_popup().connect("id_pressed", self, "_on_file_option_pressed")
	
func _on_file_option_pressed(id: int):
	$FileDialog.popup_centered()

func _on_file_selected(path):
	var log_file := File.new()
	log_file.open(path, File.READ)
	var log_text: String = log_file.get_as_text(true)
	log_file.close()
	
	clear(frames_list)
	
	var frames := log_text.split("------", false)
	for frame in frames:
		var f = FrameData.new()
		if f.parse(frame):
			var button = frame_button_template.instance()
			button.set_framedata(f)
			frames_list.add_child(button)
			button.connect("pressed", self, "_on_frame_pressed")

func _on_frame_pressed(f: FrameData):
	tree.clear()
	$log_viewer/menus/stats/time.text = "Total time: " + str(f.frame_time)
	var root:TreeItem = tree.create_item()
	root.set_text(0, "Functions")
	for fun in f.top_level_functions:
		var t:TreeItem = tree.create_item(root)
		recursive_list(t, fun)

func recursive_list(t: TreeItem, f: FrameData.FunctionProfile):
	t.set_text(0, "%s [%d]" % [f.name, f.runtime] )
	t.set_tooltip(0, "Start: %d. End: %d" % [f.start, f.end])
	for fsub in f.children:
		var tsub:TreeItem = tree.create_item(t)
		recursive_list(tsub, fsub)
	t.collapsed = true

func clear(n: Node):
	for c in n.get_children():
		c.queue_free()
