extends KinematicBody

export(NodePath) var source_path
export(bool) var gravity_stun_receiver = false
onready var main_body = get_node(source_path)

func take_damage(damage, dir, source: Node, _tag := ""):
	main_body.take_damage(damage, dir, main_body)
	if "last_attacker" in main_body:
		main_body.last_attacker = source

func gravity_stun(damage):
	if gravity_stun_receiver and main_body.has_method("gravity_stun"):
		main_body.gravity_stun(damage)
