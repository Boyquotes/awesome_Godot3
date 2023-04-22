extends Node

export(NodePath) var tower_node
export(Array, NodePath) var stair_nodes
export(Gradient) var light_gradient: Gradient

# Should be an array of mesh instances
var stairs : Array
var top : Vector3
var offset : Vector3
var level := 0

const delta := 0.1
onready var tower: MeshInstance = get_node(tower_node)
onready var player: Spatial = Global.get_player()

func _init():
	stairs = []

func _ready():
	for n in stair_nodes:
		var s = get_node(n)
		stairs.append(s)
		randomize_lights(s)
	sort_by_height()
	top = stairs[0].global_transform.origin

# Bubble sort
# O(n^2) in general, but good for mostly sorted lists
# also very simple to implement
func sort_by_height():
	# sort from highest to lowest
	var sorted = false
	var offset_sum = Vector3.ZERO
	while !sorted:
		sorted = true
		for up in range(stairs.size()-1):
			var down = up+1
			var upper = stairs[up]
			var lower = stairs[down]
			if upper.global_transform.origin.y < lower.global_transform.origin.y:
				# swapped
				stairs[down] = upper
				stairs[up] = lower
				sorted = false
				offset_sum = Vector3.ZERO
			else:
				offset_sum += lower.global_transform.origin - upper.global_transform.origin
	offset = offset_sum/(stairs.size()-1)

func _process(_delta):
	var pos = player.global_transform.origin
	var tower_local = tower.global_transform.affine_inverse()*pos
	if !tower.get_aabb().has_point(tower_local):
		return

	var overlap := -1
	for i in range(stairs.size()):
		var obj: MeshInstance = stairs[i]
		if !obj:
			print_debug("Not a MeshInstance: ", stairs[i].name)
			continue
		var local:Vector3 = obj.global_transform.affine_inverse()*pos
		if obj.get_aabb().has_point(local):
			overlap = i
			if i <= 1:
				break
	if overlap == -1:
		var player_level = (pos.y - top.y) / offset.y - stairs.size()/2.0
		while player_level > 1 and level < player_level:
			if !descend():
				break
	elif overlap <= 1:
		ascend()
	elif overlap >= stairs.size() - 2:
		descend()

func ascend():
	if level == 0:
		return
	level -= 1
	var bottom_stair = stairs.pop_back()
	stairs.push_front(bottom_stair)
	bottom_stair.global_transform.origin = top+level*offset
	randomize_lights(bottom_stair)

func descend():
	var bottom_level := level+stairs.size()
	if bottom_level*offset.y <= -5000:
		return false
	level += 1
	var top_stair = stairs.pop_front()
	stairs.push_back(top_stair)
	top_stair.global_transform.origin = top+bottom_level*offset
	randomize_lights(top_stair)
	return true

func randomize_lights(l):
	for c in l.get_children():
		if c is Light:
			var r = sin(12*c.global_transform.origin.y)/2 + 0.5
			c.light_color = light_gradient.interpolate(r)
