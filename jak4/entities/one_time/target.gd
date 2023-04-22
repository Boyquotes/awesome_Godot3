extends KinematicBody

export(NodePath) var animation_player
export(NodePath) var audio_stream_player
onready var anim = get_node(animation_player)
onready var audio = get_node(audio_stream_player)

func take_damage(_dam, dir, _source: Node, _tag := ""):
	audio.pitch_scale = rand_range(0.95, 1.5)
	anim.stop()
	var _x = Global.add_temp_stat("tut_target_hit")
	if dir.dot(global_transform.basis.z) < 0:
		anim.play("hit_front")
	else:
		anim.play("hit_back")
