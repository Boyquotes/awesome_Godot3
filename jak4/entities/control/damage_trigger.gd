extends Spatial

signal damaged
signal damage_params(damage, dir)

export(bool) var one_time := false
export(String) var ignored_tag := ""

var damage_count := 0

func get_target_ref() -> Vector3:
	if has_node("target_ref"):
		return $target_ref.global_transform.origin
	else:
		return global_transform.origin

func take_damage(damage, dir, _source: Node, tag := ""):
	if one_time and damage_count > 0:
		return
	if ignored_tag != "" and tag == ignored_tag:
		return
	emit_signal("damaged")
	emit_signal("damage_params", damage, dir)
	if one_time:
		damage_count += 1
		remove_from_group("target")
