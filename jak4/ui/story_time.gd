extends Panel

var queued_story := false
var exit_ready := false

func _ready():
	var _x = Global.connect("stat_changed", self, "_on_stat_changed")

func queue_story(key: String) -> bool:
	if Global.add_story(key):
		var s: Story = Global.stories[key]
		$ScrollContainer/Label.text = s.text
		queued_story = true
		return true
	return false

func _on_stat_changed(stat, value):
	if stat == "current_day" and value == 5:
		var _x = queue_story("lucas_birthday")

func start_countdown():
	queued_story = false
	exit_ready = false
	$input_prompt.hide()
	$timer.start()

func _on_timer_timeout():
	exit_ready = true
	$input_prompt.show()
