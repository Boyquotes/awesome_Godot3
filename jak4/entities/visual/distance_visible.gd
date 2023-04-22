extends Spatial

export(float, 0, 1000) var distance := 30.0
onready var dist_sq = distance*distance

func _ready():
	add_to_group("distance_activated")

func process_player_distance(player_pos):
	var r2 := Global.render_distance*Global.render_distance
	visible = (player_pos - global_transform.origin).length_squared() <= dist_sq*r2
