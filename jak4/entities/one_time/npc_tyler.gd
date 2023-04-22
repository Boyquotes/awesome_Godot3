extends NPC

onready var last_position := global_transform.origin
onready var player :PlayerBody = get_tree().current_scene.get_node("player")
const ROTATE_SPEED := 10.0
var look_at_player := false
var chase := false
var in_tutorial := false
var dialog_node

func _ready():
	if (Global.stat($tutorial_area.get_stat_name())):
		disable_dialog()
	idle()

func _process(delta):
	if !chase:
		set_process(false)
		return
	var current_position := global_transform.origin
	var dir : Vector3
	if look_at_player:
		dir = player.global_transform.origin - current_position
	else:
		dir = (current_position - last_position)
	
	dir.y = 0
	if dir.length() < delta*8:
		return
	dir = dir.normalized()
	var forward:Vector3 = $lil_man.global_transform.basis.z
	var axis := forward.cross(dir).normalized()
	if axis.is_normalized():
		var theta := forward.angle_to(dir)
		var angle := sign(theta)*min(abs(theta), ROTATE_SPEED*delta)
		$lil_man.global_rotate(axis, angle)
	
	last_position = current_position

func idle():
	look_at_player = true
	anim.play("Idle-loop")

func wave():
	look_at_player = true
	anim.play("Waving-loop")

func run():
	look_at_player = false
	anim.play("Run-loop")

func jump():
	look_at_player = false
	anim.play("CrouchJump")

func grab_ledge():
	look_at_player = false
	anim.play("LedgeGrab")

func climb():
	look_at_player = false
	anim.play("Climb-loop")

func fall():
	look_at_player = false
	anim.play("Air")

func start_tutorial():
	set_process(true)
	chase = true
	disable_dialog()
	in_tutorial = true
	$tutorial_area.next_stage()

func disable_dialog():
	dialog_node = $dialog
	remove_child($dialog)

func enable_dialog():
	if dialog_node:
		add_child(dialog_node)
