extends Spatial

export(NodePath) var skeleton_node : NodePath
export(NodePath) var ik_break : NodePath
export(bool) var player_velocity_influence := true

onready var skeleton := get_node(skeleton_node)
onready var ik_targets := get_node(ik_break)

func _ready():
	if !Global.get_player():
		return
	for c in skeleton.get_children():
		if c is SkeletonIK:
			c.start()
	if !player_velocity_influence:
		for c in ik_targets.get_children():
			if "player_velocity_match" in c:
				c.player_velocity_match = 0
