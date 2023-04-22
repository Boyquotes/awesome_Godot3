extends Control

signal exited(state)
signal exited_anim(animation)
signal event(id)
signal event_with_source(id, source)

var shopping := false setget set_shopping

onready var player: PlayerBody = Global.get_player()
var main_speaker: Node
var source_node: Node
var last_speaker: String

var current_item : DialogItem
var sequence: Resource

export(Dictionary) var fonts: Dictionary
export(Dictionary) var colors := {
	"narration": Color.dimgray,
	"you":Color.deeppink
}

onready var replies := $messages/replies
onready var messages := $messages/messages/list

const RESULT_SKIP := {"result":"skip"}
const RESULT_PAUSE := {"result":"pause"}
const RESULT_END := {"result":"end"}
const RESULT_NOSKIP := {"result":"noskip"}

var r_otherwise_if := RegEx.new()
var r_interpolate := RegEx.new()

var otherwise := false
var talked := 0
var skip_reply := false
var discussed: Dictionary
var is_exiting := false
# Stack of IDs for DialogItems
var call_stack: Array
var advance_on_resume := false

const SECONDS_PER_YEAR := 356*24*3600
const SECONDS_PER_MONTH := 30*24*3600
const SECONDS_PER_DAY := 24*3600
const SECONDS_PER_HOUR := 3600
const SECONDS_PER_MINUTE := 60

func _init():
	fonts = {}
	call_stack = []
	discussed = {}

func _input(event):
	if !is_visible_in_tree():
		return
	if shopping:
		if event.is_action_pressed("ui_cancel"):
			set_shopping(false)
			resume()
	elif event.is_action_pressed("ui_cancel"):
		fast_exit()
	elif event.is_action_pressed("dialog_coat"):
		trade_coats()
	elif current_item.type != DialogItem.Type.REPLY and event.is_action_pressed("ui_accept"):
		get_next()

func _process(_delta):
	var scr = $messages/messages
	scr.scroll_vertical = scr.get_v_scrollbar().max_value

func _ready():
	var _x = r_otherwise_if.compile("^\\s*otherwise\\s+if\\s+")
	_x = r_interpolate.compile("#\\{([^\\}]+)\\}")
	ui_settings_apply()
	end()

func start(p_source_node: Node, p_sequence: Resource, speaker: Node = null, starting_label:= ""):
	set_shopping(false)
	clear()
	source_node = p_source_node
	sequence = p_sequence
	if speaker:
		main_speaker = speaker
	else:
		main_speaker = source_node
	talked = Global.stat(get_talked_stat())
	set_process(true)
	set_process_input(true)
	Global.can_pause = false
	var first_index = INF
	# I forgot to specify a first item and I'm not going to bother lol
	var s: DialogItem
	if starting_label != "":
		s = sequence.get(starting_label)
		if !s:
			print_debug("No starting label '%s' in file: %s" % [
				starting_label, sequence.resource_path
			])
	if !s:
		for c in sequence.dialog.keys():
			if c < first_index:
				first_index = c
		current_item = sequence.get(first_index)
	else:
		current_item = s
	advance()

func clear():
	last_speaker = ""
	is_exiting = false
	discussed = {}
	otherwise = false
	call_stack = []
	for c in messages.get_children():
		c.queue_free()
	clear_replies()

func clear_replies():
	for c in replies.get_children():
		c.queue_free()

func get_next():
	var c = sequence.canonical_next(current_item)
	if !c:
		exit()
		return false
	else:
		current_item = c
		advance()
		return true

func advance():
	if !current_item:
		exit()
		return
	clear_replies()
	var result := false
	var noskip := false
	var font_override := ""
	otherwise = false
	while !result:
		var otherwise_used := false
		if !current_item:
			exit()
			return
		# Conditions on replies are handles in list_replies()
		if current_item.type == DialogItem.Type.REPLY:
			result = true
			break
		var cond: Array = current_item.conditions
		result = true
		font_override = ""
		for c in cond:
			var r = check_condition(c)
			if r is Dictionary and "_otherwise" in r:
				otherwise_used = true
				r = r["_otherwise"]
			if r is Dictionary:
				if r == RESULT_END:
					return
				elif r == RESULT_PAUSE:
					pause()
					return
				elif r == RESULT_SKIP:
					advance()
					return
				elif r == RESULT_NOSKIP:
					noskip = true
				elif "_format" in r:
					font_override = r._format
			elif !r:
				result = false
				break
		if !result:
			current_item = sequence.failed_next(current_item)
			if sequence.went_up:
				otherwise = false
			elif !otherwise_used:
				otherwise = true
		else:
			otherwise = false
			if current_item.text == "" and !noskip:
				current_item = sequence.canonical_next(current_item)
				result = false
	
	if current_item.text != "":
		match current_item.type:
			DialogItem.Type.MESSAGE:
				show_message(font_override)
			DialogItem.Type.REPLY:
				list_replies()
			DialogItem.Type.NARRATION:
				show_narration(font_override)

func list_replies():
	var reply: DialogItem = current_item
	otherwise = false
	while reply and reply.type == DialogItem.Type.REPLY:
		var font_override := ""
		skip_reply = false
		var cond = reply.conditions
		var result := true
		var otherwise_used := false
		for c in cond:
			var r = check_condition(c)
			if r is Dictionary and "_otherwise" in r:
				r = r["_otherwise"]
				otherwise_used = true
			if !r:
				result = false
				break
			elif r is Dictionary and "_format" in r:
				font_override = r._format
		if result:
			otherwise = false
			var b := Button.new()
			b.clip_text = false
			var l := Label.new()
			replies.add_child(b)
			b.add_child(l)
			l.anchor_left = 0
			l.anchor_right = 1
			l.anchor_top = 0
			l.anchor_bottom = 1
			l.margin_left = 10
			l.margin_right = -10
			l.margin_top = 5
			l.margin_bottom = -5
			l.autowrap = true
			l.text = reply.text
			if font_override in fonts:
				l.add_font_override("font", fonts[font_override])
			call_deferred("resize_replies")
			var r = reply
			var s = skip_reply
			var _x = b.connect("pressed", self, "choose_reply", [r, s])
		elif !otherwise_used:
			otherwise = true
		reply = sequence.next(reply)
	if replies.get_child_count() == 0:
		print("\tNo replies.")
		current_item = reply
		advance()
	$input_timer.start()

func resize_replies():
	for b in replies.get_children():
		if !(b is Button):
			continue
		var l: Label = b.get_child(0)
		b.rect_min_size.y = l.get_line_count()*l.get_line_height()*1.25 + l.margin_top + l.margin_bottom

func _on_input_timer_timeout():
	if shopping:
		if $shop.items_window.get_child_count() >= 3:
			$shop.items_window.get_child(2).grab_focus()
	else:
		replies.get_child(0).grab_focus()

func choose_reply(item: DialogItem, skip: bool):
	if !skip:
		insert_label("You: %s" % item.text, "you")
		last_speaker = "You"
	current_item = item
	get_next()

func get_speaker_name() -> String:
	if "visual_name" in main_speaker:
		return main_speaker.visual_name
	else:
		return main_speaker.name.capitalize()

func show_message(font_override: String):
	var speaker: String = current_item.speaker
	if speaker == "":
		speaker = get_speaker_name()

	var text := ""
	if speaker != last_speaker:
		text = "%s: %s" % [speaker, current_item.text]
	else:
		text = current_item.text
	last_speaker = speaker
	
	insert_label(text, speaker.to_lower(), font_override)

func show_narration(font_override: String):
	insert_label(current_item.text, "narration", font_override)

func insert_label(text: String, format: String, font_override := ""):
	var color:Color = colors["default"]
	var font:Font = fonts["default"]
	
	if font_override in fonts:
		font = fonts[font_override]
	elif format in fonts:
		font = fonts[format]
	
	if format in colors:
		color = colors[format]
	
	var label := Label.new()
	label.autowrap = true
	label.text = interpolate(text)
	if color != Color.black:
		label.add_font_override("font", font)
		label.add_color_override("font_color", color)
	messages.add_child(label)

func interpolate(line: String):
	var matches := r_interpolate.search_all(line)
	var text := line
	for m in matches:
		var ex = evaluate(m.get_string(1))
		text = text.replace(m.get_string(), str(ex))
	return text

func evaluate(ex_text: String):
	var expr: Expression = Expression.new()
	var err = expr.parse(ex_text, ["Global"])
	if err != OK:
		print_debug("\tFailed to parse {%s}. Code %d" % [ex_text, err])
		return true
	
	var r = expr.execute([Global], self)
	
	if expr.has_execute_failed():
		print_debug("\tFailed to execute {%s}.\n\t%s" 
			% [ex_text, expr.get_error_text()])
		return true
	return r

func check_condition(cond: String):
	var oif: RegExMatch = r_otherwise_if.search(cond)
	
	if cond == "otherwise":
		return {"_otherwise": otherwise}
	if oif:
		if !otherwise:
			return {"_otherwise":false}
		cond = cond.replace(oif.get_string(), "")
	
	var result = evaluate(cond)
	if oif:
		return {"_otherwise":result}
	return result

func end():
	set_process(false)
	set_process_input(false)
	Global.can_pause = true

func trade_coats():
	if mentioned("_coat"):
		get_next()
		return
	var coat_item: DialogItem = sequence.get("_coat")
	if coat_item:
		mention("_coat")
		current_item = coat_item
		advance()
	else:
		insert_label("[You cannot trade coats at this time]", "narration")

func skip_and_exit():
	if !is_exiting:
		fast_exit()
	while get_next():
		continue

func fast_exit():
	if is_exiting:
		get_next()
	else:
		is_exiting = true
		current_item = sequence.get("_exit")
		advance()

func pause():
	print("Pausing dialog...")
	set_process_input(false)
	set_process(false)

func resume():
	set_process_input(true)
	set_process(true)
	if advance_on_resume:
		get_next()

func get_talked_stat():
	var s: String = speaker_stat()
	return "talked/" + s

func ui_settings_apply():
	for f in fonts.values():
		if f is DynamicFont:
			f.size = get_theme_default_font().size
	
	fonts["default"] = get_theme_default_font()
	colors["default"] = get_color("font_color", "Label")

func set_shopping(s):
	shopping = s
	$messages.visible = !shopping
	$shop.visible = shopping
	if shopping:
		$input_timer.start()

## Dialog functions

func exiting():
	is_exiting = true
	return true

func track_conversation_time():
	Global.set_stat("talk_time"+get_speaker_name(), OS.get_unix_time())
	return true

func seconds_since_conversation() -> int:
	var prev: int = Global.stat("talk_time"+get_speaker_name())
	var now: int = OS.get_unix_time()
	return now - prev

func format(style: String):
	return {"_format":style}

# TODO
func animation(_animation: String, _node: String = ""):
	return true

func event(tag: String, should_pause := false, auto_advance_on_resume:= true):
	emit_signal("event", tag)
	emit_signal("event_with_source", tag, main_speaker)
	if main_speaker.has_method(tag):
		main_speaker.call(tag)
	if should_pause:
		advance_on_resume = auto_advance_on_resume
		return RESULT_PAUSE
	else:
		return true

func goto(label: String):
	current_item = sequence.get(label)
	return RESULT_SKIP

func skip():
	skip_reply = true
	# Ironic how skip() does not return RESULT_SKIP
	return true

func noskip():
	return RESULT_NOSKIP

func exit(state := PlayerBody.State.Ground):
	var stat: String = get_talked_stat()
	var _x = Global.add_stat(stat)
	emit_signal("exited", state)
	set_process_input(false)
	return RESULT_END

func exit_anim(animation:String):
	var stat: String = get_talked_stat()
	var _x = Global.add_stat(stat)
	emit_signal("exited_anim", animation)
	set_process_input(false)
	return RESULT_END

func mention(topic):
	discussed[topic] = true
	return true

func mentioned(topic):
	return topic in discussed

func subtopic(label):
	call_stack.push_back(current_item)
	return goto(label)

func back():
	# If there's nothing on the call stack, we just continue
	if call_stack.empty():
		return true
	var caller = call_stack.pop_back()
	current_item = sequence.canonical_next(caller)
	return RESULT_SKIP

func coat_trade_stat() -> String:
	return "coat_trade/" + speaker_stat()

func traded_coats():
	return Global.stat(coat_trade_stat())

func swap_coats():
	var _x = Global.add_stat(coat_trade_stat())
	_x = Global.add_stat("trade_coat")
	var player_coat: Coat = player.current_coat
	var speaker_coat: Coat = main_speaker.get_coat()
	main_speaker.set_coat(player_coat)
	Global.add_coat(speaker_coat)
	player.set_current_coat(speaker_coat, true)
	Global.remove_coat(player_coat)
	return true

func speaker_stat() -> String:
	if !main_speaker:
		return "_NO_SPEAKER_"
	if "friendly_id" in main_speaker and main_speaker.friendly_id != "":
		return main_speaker.friendly_id
	else:
		return Global.node_stat(main_speaker)

func can_discuss(stat: String) -> bool:
	return Global.stat(stat) and !Global.stat("discussed/" + speaker_stat() + "/" + stat)

func mark_discussed(stat: String) -> bool:
	var _x = Global.add_stat("discussed/" + speaker_stat() + "/" + stat)
	return true

func shop():
	set_shopping(true)
	$shop.start_shopping(main_speaker)
	return true

func remember(note: String, subject: String = ""):
	if subject == "":
		subject = get_speaker_name()
	Global.add_note("people", subject, note)
	return true

func knows(person: String):
	return Global.has_note("people", person)

func task_exists(id):
	return Global.task_exists(id)

func task_is_active(id):
	return Global.task_is_active(id)

func task_is_complete(id):
	return Global.task_is_complete(id)

func stat(s: String):
	return Global.stat(s)

func playing_game() -> bool:
	return CustomGames.is_playing(main_speaker.get_parent())

func has_game_stat(sub_stat) -> bool:
	return CustomGames.has_stat(main_speaker.get_parent(), sub_stat)

func game_stat(sub_stat):
	return CustomGames.stat(main_speaker.get_parent(), sub_stat)

func game_completed():
	return CustomGames.completed(main_speaker.get_parent())

func game_start():
	return main_speaker.get_parent().start()

func control_screen(val := true):
	$"../black".visible = val
