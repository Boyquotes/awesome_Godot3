extends Control

onready var scroll_area := $scrollable_map
onready var reticle := $reticle
onready var panel := $reticle/panel

var active := false
var show_background := true

var snap_timer := 0.0
var snap_direction := Vector2.ZERO
var zoom_scale := 1.0

var last_moved_dir := Vector2.ZERO
var highlighted_point = null
var min_pos : Vector2
var max_pos : Vector2
var mouse_accum : Vector2

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_LEFT):
		mouse_accum += event.relative

func _ready():
	set_active(false)

func _process(delta: float):
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		reticle.global_position = get_global_mouse_position()
		pass
	else:
		mouse_accum = Vector2.ZERO
		# Snap
		if snap_timer > 0:
			var ratio = clamp(delta*10, 0.0, 0.1)
			snap_timer *= 1 - ratio
			var snap_move = ratio*snap_direction
			snap_direction *= 1 - ratio
			if snap_timer < 0.01:
				snap_timer = 0
			scroll_area.position -= snap_move
	# Zoom
	var zoom := Input.get_axis("map_zoom_out", "map_zoom_in") + Global.get_mouse_zoom_axis()
	if zoom != 0:
		var rel_pos = reticle.global_position - scroll_area.global_position
		var zoom_change =  pow(1 + delta, zoom)
		var new_zoom = clamp(zoom_scale*zoom_change, 1, 4)
		zoom_change = new_zoom/zoom_scale
		zoom_scale = new_zoom
		scroll_area.scale = Vector2(zoom_scale, zoom_scale)
		scroll_area.translate(rel_pos - zoom_change*rel_pos)
		update_zoom()
	# Movement
	var movement = Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	if movement != Vector2.ZERO:
		last_moved_dir = movement
	scroll_area.translate(-delta*400*movement + mouse_accum)
	scroll_area.position.x = clamp(scroll_area.position.x, min_pos.x, max_pos.x)
	scroll_area.position.y = clamp(scroll_area.position.y, min_pos.y, max_pos.y)
	
	# Find snap target
	var best_dist := 60
	var old_point = highlighted_point
	highlighted_point = null
	for g in scroll_area.get_children():
		if !(g is KinematicBody2D) or !g.visible:
			continue
		var dir = g.global_transform.origin - reticle.global_transform.origin
		
		var dist = dir.length()
		if dist < best_dist and dist < 40:
			best_dist = dist
			highlighted_point = g
		if dir.dot(last_moved_dir) <= 0:
			continue
		if dist <= best_dist and dist > 10:
			best_dist = dist
			snap_direction = dir
			snap_timer = 1.0
	if !highlighted_point and panel.visible:
		panel.hide()
	elif highlighted_point != old_point:
		panel.show()
		panel.get_node("vbox/Label").text = highlighted_point.visual_name
		var head = panel.get_node("vbox/headline")
		
		if highlighted_point.headline != "":
			head.text = highlighted_point.headline
			head.show()
		else:
			head.hide()
		var note_box:Container = panel.get_node("vbox/Notes")
		for c in note_box.get_children():
			c.queue_free()
		for n in highlighted_point.notes:
			var l = Label.new()
			l.autowrap = true
			l.size_flags_horizontal = SIZE_EXPAND_FILL
			l.text = n
			note_box.add_child(l)
	mouse_accum = Vector2.ZERO

func update_zoom():
	max_pos = OS.window_size/2 + zoom_scale*scroll_area.texture.get_size()/2
	min_pos = -zoom_scale*scroll_area.texture.get_size()/2 + OS.window_size/2

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_active(is_visible_in_tree())

func set_active(a):
	reticle.global_position = OS.window_size/2
	zoom_scale = 1
	scroll_area.scale = Vector2(1, 1)
	active = a
	set_process(active)
	set_process_input(active)
	if active:
		update_zoom()
		for g in scroll_area.get_children():
			var t = Global.task_notes_by_place(g.name)
			var n = Global.get_notes("places", g.name)
			if t and !t.empty():
				g.notes = t
			if n and !n.empty():
				g.headline = n[n.size() - 1]

			if (!t or t.empty()) and (!n or n.empty()):
				g.hide()
			else:
				g.show()
