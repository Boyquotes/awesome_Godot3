extends PhysicsBody

export(NodePath) var mesh_path = NodePath("..")

onready var node: GeometryInstance

export(bool) var double_sided := false
export(bool) var persistent := true

var coat: Coat

func _ready():
	if has_node(mesh_path):
		node = get_node(mesh_path)
	if persistent:
		var c = Global.stat("coats/" + Global.node_stat(self))
		if !(c is Coat):
			c = Coat.new(true)
		set_coat(c)
	else:
		set_coat(Coat.new(true))

func get_coat():
	return coat

func set_coat(c: Coat):
	coat = c
	var mat = coat.generate_material(!double_sided)
	if node:
		node.material_override = mat
	else:
		for c in get_children():
			if c is GeometryInstance:
				c.material_override = mat

	if persistent:
		Global.set_stat("coats/" + Global.node_stat(self), c)
	if has_node("light"):
		var l := $light as Light
		if l:
			var c_start: Color = coat.gradient.interpolate(0.0)
			var c_end: Color = coat.gradient.interpolate(1.0)
			var c_mid: Color = coat.gradient.interpolate(0.5)
			l.light_color = (c_start + c_end + c_mid)/3

func start_coat_trade(player: PlayerBody):
	var _x = Global.add_stat("find_coat")
	var player_coat: Coat = player.current_coat
	var this_coat: Coat = get_coat()
	Global.add_coat(this_coat)
	player.set_current_coat(this_coat, true)
	Global.remove_coat(player_coat)
	set_coat(player_coat)
