extends ImmediateGeometry

export(int, 2, 1024) var segments := 16.0
export(float) var length := 1.0
export(float) var width := 0.03
export(Vector3) var starting_velocity := Vector3.ZERO
export(Vector3) var random_velocity := Vector3.ZERO
export(Gradient) var color: Gradient
export(float) var cull_distance := 10.0

var position: PoolVector3Array = []
var velocity: PoolVector3Array = []

func _ready():
	set_active(visible)

func _process(delta):
	if position.size() == 0:
		add_point()
		add_point()
	position[0] = global_transform.origin
	var d := position[0] - position[1]
	var max_d := length/(segments)
	if d.length_squared() > max_d*max_d:
		add_point()
	
	for i in position.size():
		position[i] += velocity[i]*delta
	
	var camb: Basis = get_viewport().get_camera().global_transform.basis
	
	clear()
	begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in position.size() - 1:
		var g_pos := position[i]
		var g_next := position[i+1]
		var dir := g_next - g_pos
		var prev := Vector3.ZERO
		if i > 0:
			prev = g_pos - position[i-1]
		var nprev := prev.slide(camb.z).normalized()
		var ndir := dir.slide(camb.z).normalized()
		var third: Vector3 = (ndir - nprev).normalized()*width*(segments-i)/segments
		if third.dot(camb.x) < 0:
			third = -third
		var fourth := third
		if i < position.size() - 2:
			var next := position[i+2] - g_next
			var nnext = next.slide(camb.z).normalized()
			fourth = (nnext - ndir).normalized()*width*(segments-1-i)/segments
			if fourth.dot(camb.x) < 0:
				fourth = -fourth
		
		var point1 = global_transform.xform_inv(g_pos)
		var point2 = global_transform.xform_inv(g_next)
		var point3 = global_transform.xform_inv(g_pos + third)
		var point4 = global_transform.xform_inv(g_next + fourth)
		
		add_vertex(point1)
		add_vertex(point2)
		add_vertex(point3)
		
		add_vertex(point3)
		add_vertex(point2)
		add_vertex(point4)
	end()

func add_point():
	while position.size() > segments:
		position.remove(position.size() - 1)
		velocity.remove(velocity.size() - 1)
		velocity[velocity.size() - 1] *= 0.1
		velocity[velocity.size() - 2] = position[position.size() - 1] - position[position.size() - 2]
	if velocity.size() > 0:
		velocity[0] = starting_velocity + 2*random_velocity*Vector3(
				randf(), randf(), randf()
			) - random_velocity
		velocity[0] = global_transform.basis*velocity[0]
	position.insert(0, global_transform.origin)
	velocity.insert(0, Vector3.ZERO)

func process_player_distance(point):
	if (point - global_transform.origin).length_squared() > cull_distance*cull_distance:
		if visible:
			set_active(false)
	elif !visible:
		set_active(true)
	return INF

func set_active(active: bool):
	visible = active
	set_process(active)
