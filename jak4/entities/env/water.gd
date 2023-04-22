extends Node

export(NodePath) var water = NodePath("mesh")

func get_ripple_color():
	if has_node(water):
		var w = get_node(water)
		var s:ShaderMaterial = w.get_active_material(0)
		if s and s.shader.has_param("foam_color"):
			return s.get_shader_param("foam_color")
	return Color.white
