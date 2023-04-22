tool
extends EditorImportPlugin
class_name NPDialogImportPlugin

var NPSequence = preload("res://addons/np_dialog/resource/sequence.gd")

var r_comment := RegEx.new()
var r_whitespace_start := RegEx.new()
var r_label := RegEx.new()
var r_expression := RegEx.new()
var r_narrate := RegEx.new()
var r_reply := RegEx.new()
var r_speaker := RegEx.new()

var f_query := "Global.stat('%s')"
var f_add := "Global.add_stat('%s')"
var f_not := "!Global.stat('%s')"

func _init():
	r_comment.compile("^\\s*//")
	r_whitespace_start.compile("^(\\s+)")
	r_label.compile("^\\s*:(\\w+)")
	r_expression.compile("[#+!?]?\\{([^\\}]+)\\}")
	r_narrate.compile("^\\s*\\*\\s*")
	r_reply.compile("^\\s*>\\s*")
	r_speaker.compile("^\\s*\\[([^\\]]+)]\\s*")

func get_importer_name():
	return "np.dialog"

func get_visible_name():
	return "NP Dialog"

func get_recognized_extensions():
	return ["dialog"]

func get_save_extension():
	return "tres"

func get_resource_type():
	return "Resource"

func get_preset_count():
	return 1

func get_preset_name(_preset):
	return "NP Dialog"

func get_import_options(preset):
	return []

func import(src_path: String, 
	dest_path: String,
	options: Dictionary, 
	r_platform_variants: Array, 
	r_gen_files: Array
):
	var in_file := File.new()
	var err := in_file.open(src_path, File.READ)
	if err != OK:
		print_debug("NP Dialog failed to import %s, error code %d" 
			% [src_path, err])
		return err
	
	var text := in_file.get_as_text()
	in_file.close()
	
	var seq = parse_text(text, src_path)
	if !(seq is Resource) or !("dialog" in seq):
		print_debug("Encountered an error: ", seq)
		return seq

	var out_path: String = "%s.%s" % [dest_path, get_save_extension()]
	err = ResourceSaver.save(out_path, seq)
	if err != OK:
		print_debug("NP Dialog failed to save %s, error code %d" 
			% [out_path, err])
		return err

	return OK

func parse_text(text: String, src_path = "<local>"):
	var seq = NPSequence.new()
	
	var current_dialog := -1
	var prev: DialogItem
	var current_level := 0
	var indent := ""
	var label := ""
	
	var line_number := 0
	
	for line in text.split("\n", true):
		line_number += 1
		if r_comment.search(line) or line.strip_edges() == "":
			continue
		
		var label_search := r_label.search(line)
		if label_search:
			label = label_search.get_string(1)
			continue
		# Whitespace and indentation
		var wspe := extract_whitespace(line, indent, src_path, line_number)

		var wd := DialogItem.new()
		seq.dialog[line_number] = wd
		
		var sp := extract_expressions(line)
		line = sp.line
		wd.conditions = sp.conditions
		
		var td := extract_type(line)
		line = td.line
		wd.type = td.type

		var nd := extract_speaker(line)
		if "speaker" in nd:
			wd.speaker = nd.speaker
		if "line" in nd:
			line = nd.line
		
		wd.text = line.strip_edges()
		
		if "indent" in wspe:
			indent = wspe.indent
		var level_change: int = wspe.indent_level - current_level
		if level_change > 1:
			print_debug("ERROR %s [line %d]: Extra indentation" % [
				src_path, line_number
			])
			level_change = 1

		# Inserting the working dialog item into the tree
		if current_dialog == -1:
			# No parent issues
			pass
		elif level_change == 0:
			prev.next = line_number
			wd.parent = prev.parent
		elif level_change == 1:
			prev.child = line_number
			wd.parent = current_dialog
		else:
			var lv:int = level_change
			var previous: DialogItem = prev
			while lv < 0:
				if previous.parent == -1:
					print_debug("BUG %s [line %d]: Indented block with no parent" % [
						src_path, line_number
					])
					return ERR_BUG
				previous = seq.dialog[previous.parent]
				lv += 1
			previous.next = line_number
			wd.parent = previous.parent
		
		if ( wd.speaker == "" 
			and wd.parent in seq.dialog
			and seq.dialog[wd.parent].speaker != ""
		):
			wd.speaker = seq.dialog[wd.parent].speaker.strip_edges()
			
		current_dialog = line_number
		current_level += level_change
		prev = wd
		if label != "":
			seq.labels[label] = line_number
		label = ""
	return seq

func extract_whitespace(line: String, indent: String, src_path, line_number) -> Dictionary:
	var dict := {}
	var space := ""
	
	var whitespace := r_whitespace_start.search(line)
	if whitespace:
		space = whitespace.get_string(1)
		if indent == "":
			dict.indent = space
			indent = space

	if space != "" and (space.length() % indent.length() != 0):
		print_debug("ERROR %s [line %d]: Invalid indentation of length %d" % [
			src_path, line_number, space.length()
		])

	if space.length() != 0:
		dict.indent_level = space.length() / indent.length()
	else:
		dict.indent_level = 0
	return dict

func extract_expressions(line: String) -> Dictionary:
	var dict = {}
	dict.line = line
	dict.conditions = []
	var matches = r_expression.search_all(line)
	for rm in matches:
		var s: String=  rm.get_string()
		if s.begins_with("#"):
			continue
		
		var ex : String = rm.get_string(1)
		dict.line = dict.line.replace(s, "")
		if s.begins_with("?"):
			ex = f_query % ex
		elif s.begins_with("+"):
			ex = f_add % ex
		elif s.begins_with("!"):
			ex = f_not % ex
		dict.conditions.append(ex)
	return dict

func extract_type(line: String) -> Dictionary:
	var dict = {}
	var nm = r_narrate.search(line)
	if nm:
		dict.type = DialogItem.Type.NARRATION
		dict.line = line.replace(nm.get_string(), "")
	else:
		var rm = r_reply.search(line)
		if rm:
			dict.type = DialogItem.Type.REPLY
			dict.line = line.replace(rm.get_string(), "")
		else:
			dict.type = DialogItem.Type.MESSAGE
			dict.line = line
	return dict

func extract_speaker(line: String) -> Dictionary:
	var dict = {}
	var m = r_speaker.search(line)
	if m:
		dict.speaker = m.get_string(1)
		dict.line = line.replace(m.get_string(), "")
	return dict
