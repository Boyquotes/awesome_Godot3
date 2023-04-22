extends Control

export(String) var action setget set_action
export(bool) var small := false

var default_size = rect_size

# device/input event
const prompt_path := "res://ui/prompts/%s/%s.png"

func _ready():
	default_size = rect_size
	var _x = connect("visibility_changed", self, "_refresh")

func _refresh():
	set_action(action)

func set_action(a):
	action = a
	if action == "":
		$texture.hide()
		$key_prompt.hide()
		return

	if !InputMap.has_action(action):
		print_debug("MISSING_ACTION: ", action, " FOR NODE: ", get_path())
		show_text(action)
		return
	
	var input_str = Global.get_action_input_string(action)
	if !Global.using_gamepad:
		show_text(input_str)
	else:
		var device = "pad_generic"
		var prompt = prompt_path % [device, input_str]
		if ResourceLoader.exists(prompt):
			var t = load(prompt)
			show_image(t)
		else:
			show_text(input_str)

func show_image(image: Texture):
	$key_prompt.hide()
	$texture.show()
	$texture.texture = image
	var s = image.get_size()
	if small:
		s /= 3
	rect_size = s
	$texture.rect_min_size = s

func show_text(text):
	$texture.hide()
	$key_prompt.show()
	$key_prompt/Label.text = text
	rect_size = default_size
