tool
extends EditorScript

func _run():
	var c:Chunk = get_scene()
	if !c:
		return
	
	var m:MeshInstance = c.get_node("__autogen_preview")
	if !m:
		return
	
	var g:MultiMeshInstance
	if c.has_node(c.grass_node):
		g = c.get_node(c.grass_node)
	if !g:
		return
	
	var mesh: Mesh = m.mesh
	if !mesh:
		return
	
	g.multimesh.instance_count = 0
	g.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	g.multimesh.color_format = MultiMesh.COLOR_NONE
	g.multimesh.custom_data_format = MultiMesh.CUSTOM_DATA_8BIT
	
	var arrays = mesh.surface_get_arrays(0)
	
	var verts = arrays[Mesh.ARRAY_VERTEX]
	var colors = arrays[Mesh.ARRAY_COLOR]
	var normals = arrays[Mesh.ARRAY_NORMAL]
	var index = arrays[Mesh.ARRAY_INDEX]
	
	print("Adding to triangles:", index.size()/3)
	
	var tri := 0
	var transforms := []
	var out_colors := []
	while tri < index.size():
		var v0:int = index[tri]
		var v1:int = index[tri + 1]
		var v2:int = index[tri + 2]
		tri += 3
		
		var face_normal:Vector3 = -(verts[v1] - verts[v0]).cross(verts[v2] - verts[v0]).normalized()
		var total_density:float = colors[v0].g + colors[v1].g + colors[v2].g

		if  total_density <= 0.2:
			continue
		if face_normal.y < 0.8:
			continue
		
		var area:float = (verts[v0] - verts[v1]).length()*(verts[v0] - verts[v2]).length()/2

		for _i in range(int(area*c.grass_density*total_density*face_normal.y/3.0)):
			var t := Transform.IDENTITY
			var point = average(
				verts[v0], verts[v1], verts[v2],
				colors[v0].g, colors[v1].g, colors[v2].g)
			t.origin = (
				point.x*verts[v0]
				+ point.y*verts[v1]
				+ point.z*verts[v2])

			var normal_at_point = (
				point.x*normals[v0]
				+ point.y*normals[v1]
				+ point.z*normals[v2])
				
			var color_at_point = mix3(
				point,
				colors[v0],
				colors[v1],
				colors[v2])
			
			var dir := Vector3(face_normal.z, face_normal.x, face_normal.y)*0.3 + 2*Vector3(randf(), randf(), randf()) - Vector3(1,1,1)
			dir = dir.slide(face_normal)
			t = t.looking_at(t.origin + dir, face_normal)
			transforms.append(t)
			out_colors.append(color(normal_at_point, color_at_point.g))

	g.multimesh.instance_count = transforms.size()
	g.multimesh.visible_instance_count = transforms.size()
	var i = 0
	for t in transforms:
		g.multimesh.set_instance_transform(i, t)
		g.multimesh.set_instance_custom_data(i, out_colors[i])
		i += 1

func mix3(mix:Vector3, c0:Color, c1:Color, c2:Color) -> Color:
	return Color(
		c0.r*mix.x + c1.r*mix.y + c2.r*mix.z,
		c0.g*mix.x + c1.g*mix.y + c2.g*mix.z,
		c0.b*mix.x + c1.b*mix.y + c2.b*mix.z
	)

func average(v0,v1,v2, _g0,_g1,_g2):
	var a := randf()
	var b := randf()
	
	return Vector3(1.0 - sqrt(a),  sqrt(a)*(1 - b), b*sqrt(a))

func weighted_average(v0:Vector3, v1:Vector3, v2:Vector3, g0:float, g1:float, g2:float) -> Vector3:
	if g0 <= 0:
		g0 = 0.01
	if g1 <= 0:
		g1 = 0.01
	if g2 <= 0:
		g2 = 0.01

	var center := (v0 + v1 + v2)/3.0
	v0 -= center
	v1 -= center
	v2 -= center
	
	v0 = v0*g0
	v1 = v1*g1
	v2 = v2*g2
	
	# Sample the triangle
	var offset := Vector3.ZERO
	# Transform back into absolute space
	
	return center + offset

# Straight from the terrain shader
func color(normal:Vector3, ground_green:float):
	var color_black = Color8(220, 128, 105)
	var color_green = Color8(101, 130, 81)
	var color_x = Color8(113, 44, 37)
	var color_y_up = lerp(color_black, color_green, ground_green)
	var y_pow = sign(normal.y)*pow(abs(normal.y), 5)
	
	var out_color:Color = (
		color_x*pow(normal.x, 2) 
		+ color_x*pow(normal.z, 2)
		+ color_y_up*max(y_pow, 0.0)
		+ color_x*max(-y_pow, 0.0)
	)
	return out_color
