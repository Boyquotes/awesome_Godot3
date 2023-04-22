extends Spatial

enum ProcessMode {
	Physics,
	Idle
}

export(ProcessMode) var process_mode = ProcessMode.Idle
export(NodePath) var target_node : NodePath
export(Vector3) var offset := Vector3.ZERO

var target: Spatial

func _ready():
	if has_node(target_node):
		target = get_node(target_node)
		
	if !target:
		set_physics_process(false)
		set_process(false)
	elif process_mode == ProcessMode.Idle:
		set_physics_process(false)
		set_process(true)
	else:
		set_physics_process(true)
		set_process(false)

func _process(_delta):
	global_transform.origin = target.global_transform.origin + offset

func _physics_process(_delta):
	global_transform.origin = target.global_transform.origin + offset
