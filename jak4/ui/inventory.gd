extends Control

onready var viewport := $Viewport
onready var object_ref := $Viewport/object_ref
onready var ref_cam_arm := $Viewport/SpringArm

onready var view_window := $box/viewport_window
onready var items_list := $box/large_items/ScrollContainer/rows
onready var item_name := $box/viewport_window/Panel/MarginContainer/item/name
onready var item_desc := $box/viewport_window/Panel/MarginContainer/item/description
onready var sub_items := $box/viewport_window/Panel/MarginContainer/item/sub_items

export(Resource) var player_description

var preview_path := "res://ui/items/%s.tres"
var show_background := true

const DEFAULT_ICONS := {
	ItemDescription.Category.Equipment: preload("res://ui/items/icons/default_equipment.svg"),
	ItemDescription.Category.Firearm: preload("res://ui/items/icons/default_firearm.svg"),
	ItemDescription.Category.Sundries: preload("res://ui/items/icons/default_sundries.svg"),
	ItemDescription.Category.Keys: preload("res://ui/items/icons/default_keys.svg")
}

const MIN_ZOOM := 0.1
const MAX_ZOOM := 10.0
const ZOOM_SPEED := 3.0

var mouse_accum := Vector2.ZERO
var mouse_sns := Vector2(0.01, 0.01)

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_LEFT):
		mouse_accum += event.relative

func _ready():
	set_active(false)

func _process(delta):
	var cam := Input.get_vector("cam_left", "cam_right", "cam_down", "cam_up")
	mouse_accum.y *= -1
	cam += mouse_accum*mouse_sns
	var player = Global.get_player()
	if player:
		if player.invert_x:
			cam.x *= -1
		if player.invert_y:
			cam.y *= -1
	mouse_accum = Vector2.ZERO
	
	object_ref.global_rotate(Vector3.UP, cam.x*delta)
	object_ref.global_rotate(Vector3.RIGHT, -cam.y*delta)
	var zoom := Input.get_axis("map_zoom_in", "map_zoom_out") - Global.get_mouse_zoom_axis()
	var c_zoom: float = ref_cam_arm.spring_length
	c_zoom = clamp(
		c_zoom + delta * ZOOM_SPEED * c_zoom * zoom * 0.5,
		MIN_ZOOM, MAX_ZOOM)
	ref_cam_arm.spring_length = c_zoom

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_active(is_visible_in_tree())

func set_active(active):
	if active:
		var p = Global.get_player()
		if p:
			mouse_sns = 60*p.sensitivity*p.cam_rig.mouse_sns
			
		viewport.size = view_window.rect_size
		clear(items_list)
		var items := {}
		for c in Global.game_state.inventory.keys():
			var path: String = preview_path % c
			if Global.count(c) > 0 and ResourceLoader.exists(path):
				var r := ResourceLoader.load(path) as ItemDescription
				if !r:
					print_debug("Invalid item: ", path)
				else:
					items[c] = r
		view_items(items)
	set_process(active)
	set_process_input(active)

func view_items(items: Dictionary):
	var button = Button.new()
	var player_button: Button = button.duplicate()
	player_button.text = "You"
	player_button.icon = player_description.custom_icon
	var _y = player_button.connect("focus_entered", self, "_on_item_focused", [player_description])
	items_list.add_child(player_button)
	
	var sorted_items = items.values()
	sorted_items.sort_custom(self, "sort_items")
	
	for item in sorted_items:
		var b: Button = button.duplicate()
		b.text = item.full_name
		if item.custom_icon:
			b.icon = item.custom_icon
		else:
			b.icon = DEFAULT_ICONS[item.category]
		var _x = b.connect("focus_entered", self, "_on_item_focused", [item])
		items_list.add_child(b)
	
	player_button.grab_focus()

func _on_item_focused(item: ItemDescription):
	clear(sub_items)
	clear(object_ref)
	object_ref.add_child(item.preview_3d.instance())
	item_name.text = item.full_name
	item_desc.text = item.description
	for i2 in item.extra_items.keys():
		if Global.count(i2) > 0:
			var l1 := Label.new()
			l1.text = item.extra_items[i2] + ":"
			var l2 := Label.new()
			l2.text = str(Global.count(i2))
			sub_items.add_child(l1)
			sub_items.add_child(l2)

func sort_items(a: ItemDescription, b:ItemDescription):
	if a.category < b.category:
		return true
	elif b.category < a.category:
		return false
	else:
		return a.full_name < b.full_name

func clear(node: Node):
	for c in node.get_children():
		c.queue_free()
