extends Spatial
class_name DialogCircle

const vis_distance := 10.0
const sq_distance_visible := vis_distance*vis_distance
var enabled := true

onready var mat: ShaderMaterial = $Circle.get_active_material(0)

func _ready():
	if !Global.get_player():
		mat.set_shader_param("world_player", Vector3.ZERO)
		set_process(false)

func process_player_distance(origin: Vector3):
	if !enabled:
		visible = false
		return
	var sq_dist = (origin - global_transform.origin).length_squared()
	var vis = sq_dist < sq_distance_visible
	if visible != vis:
		visible = vis
	return INF

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)

func _process(_delta):
	mat.set_shader_param("world_player", Global.get_player().global_transform.origin)
