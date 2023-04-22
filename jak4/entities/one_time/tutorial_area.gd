extends Area

signal tutorial_complete

export(NodePath) var prompts_node
export(String) var id
onready var prompts = get_node(prompts_node)

var stage := 0
onready var tyler := get_parent()
onready var player := Global.get_player()

func _ready():
	if Global.stat(get_stat_name()):
		tyler.chase = false
		queue_free()

func _on_tutorial_area_body_entered(_body):
	if stage != 0:
		next_stage()

func next_stage():
	if stage == 0:
		for c in prompts.get_children():
			if "enabled" in c:
				c.enabled = true
	var anim := "TutStage" + str(stage)
	stage += 1
	if $tutorial_anim.has_animation(anim):
		$tutorial_anim.play(anim)
	else:
		end_tutorial()
		tyler.enable_dialog()
	$CollisionShape.disabled = true

func end_tutorial():
	tyler.in_tutorial = false
	tyler.chase = false
	tyler.idle()
	var _x = Global.add_stat(get_stat_name())
	emit_signal("tutorial_complete")
	for c in prompts.get_children():
		if "enabled" in c:
			c.enabled = false

func _on_AnimationPlayer_animation_finished(_anim_name):
	$CollisionShape.disabled = false
	tyler.wave()

func get_stat_name() -> String:
	return id
