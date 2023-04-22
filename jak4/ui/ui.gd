extends Control

enum Mode {
	Paused,
	Gameing,
	Dialog,
	DebugConsole,
	StoryTime,
	Custom
}

var mode:int = Mode.Gameing setget set_mode
var mode_before_pause:int = Mode.Gameing

export(Color) var stamina_color = Color(0xacff97)
export(Color) var drained_stamina_color = Color.red
onready var game := $gameing
onready var dialog := $dialog/viewer
onready var status := $status_menu
onready var health_bar := $gameing/stats/health/base
onready var stamina_bar := $gameing/stats/stamina/base
onready var armor_bar := $gameing/stats/health/extra
onready var energy_bar := $gameing/stats/stamina/extra
onready var equipment := $gameing/equipment
var equipment_path_f := "res://items/usable/%s.gd"

var custom_ui : Control
var loaded_ui : PackedScene

const VISIBLE_ITEMS := [
	"bug",
	"capacitor",
	"gem",
]

const UPGRADE_ITEMS := [
	"armor",
	"damage_up",
	"health_up",
	"jump_height_up",
	"move_speed_up",
	"stamina_booster",
	"stamina_up",
	"hover_speed_up"
]

var AMMO := {
	"pistol" : 100,
	"wave_shot" : 70,
	"grav_gun" : 40
}

const WEAPONS := [
	"wep_pistol",
	"wep_wave_shot",
	"wep_grav_gun",
	"wep_time_gun"
]

var choose_time := 0.0
const TIME_CHOOSE_ITEM := 0.25

var equipment_inventory: Dictionary
onready var player := get_parent()
var choosing_item := false

func _init():
	equipment_inventory = {}

func _ready():
	var _x = Global.connect("item_changed", self, "on_item_changed")
	_x = Global.connect("journal_updated", self, "on_journal_updated")
	set_mode(Mode.Gameing)
	set_process_input(true)

func activate():
	update_inventory(true)
	update_health()
	equip(0)

func _input(event):
	match mode:
		Mode.Gameing, Mode.Dialog:
			if event.is_action_pressed("pause"):
				set_mode(Mode.Paused)
				get_tree().set_input_as_handled()
			elif event.is_action_pressed("debug_console"):
				set_mode(Mode.DebugConsole)
				get_tree().set_input_as_handled()
		Mode.Paused:
			if event.is_action_pressed("pause"):
				var _x = unpause()
				get_tree().set_input_as_handled()
			elif event.is_action_pressed("ui_page_up"):
				status.next()
				get_tree().set_input_as_handled()
			elif event.is_action_pressed("ui_page_down"):
				status.prev()
				get_tree().set_input_as_handled()
			elif event.is_action_pressed("debug_console"):
				set_mode(Mode.DebugConsole)
				get_tree().set_input_as_handled()
		Mode.Custom:
			if event.is_action_pressed("pause"):
				set_mode(Mode.Gameing)
				get_tree().set_input_as_handled()
			elif event.is_action_pressed("debug_console"):
				set_mode(Mode.DebugConsole)
				get_tree().set_input_as_handled()
		Mode.DebugConsole:
			if event.is_action_pressed("debug_console"):
				var _x = unpause()
				get_tree().set_input_as_handled()
		Mode.StoryTime:
			if !$story_time.exit_ready:
				return
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
				set_mode(Mode.Paused)

func _process(delta):
	if mode == Mode.Gameing:
		update_stamina()
		var scn = get_tree().current_scene
		if scn.has_method("get_time"):
			$gameing/debug/stats/a10.text = "Time: " + str(scn.get_time())
		$gameing/debug/stats/a7.text = str(player.timers)
	
		$gameing/debug/stats/a4.text = "Gr: " + str(player.ground_normal)
		if player.holding("choose_item"):
			choose_time += delta
			if choose_time > TIME_CHOOSE_ITEM:
				choosing_item = true
				equipment.open()
		else:
			choose_time = 0
		
		if choosing_item and !player.holding("choose_item"):
			choosing_item = false
			equipment.close()

func update_inventory(startup:= false):
	for item in Global.game_state.inventory.keys():
		on_item_changed(item, 0, Global.count(item), startup)
	for item in UPGRADE_ITEMS:
		on_item_changed(item, 0, Global.count(item), startup)
	$gameing/weapon/ammo/ammo_label.text = str(Global.count(player.current_weapon))

func update_health():
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	health_bar.value = player.health
	armor_bar.max_value = player.armor*player.ARMOR_BOOST
	armor_bar.value = player.extra_health

func update_stamina():
	energy_bar.rect_min_size.x = player.extra_stamina*player.EXTRA_STAMINA_BAR_SIZE
	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina
	if player.stamina < player.STAMINA_DRAIN_WALLJUMP:
		stamina_bar.modulate = drained_stamina_color
	else:
		stamina_bar.modulate = stamina_color

func on_item_changed(item: String, change: int, count: int, startup := false):
	if item in VISIBLE_ITEMS:
		if !startup and !Global.stat("tutorial/items"):
			var _x = Global.add_stat("tutorial/items")
			show_prompt(["show_inventory"], "Show Inventory")
		var l_count: Label = get_node("gameing/inventory/"+item+"_count")
		l_count.text = str(count)
		if change != 0:
			var added: Label = get_node("gameing/inventory/"+item+"_added")
			var c = change
			if added.modulate.a > 0.01:
				var old_added = int(added.text)
				c = change + old_added
			added.text = "+ "+str(c) if c > 0 else "- "+str(abs(c))
			var anim = added.get_node("AnimationPlayer")
			anim.stop()
			anim.play("show")
		show_specific_item(item)
	elif item in WEAPONS:
		if count > 0:
			player.gun.add_weapon(item, startup)
			if !startup:
				player.gun.swap_to(item)
			show_ammo()
			if !startup:
				match item:
					"wep_pistol":
						show_prompt(["wep_1"], tr("Pistol"))
					"wep_wave_shot":
						show_prompt(["wep_2"], tr("Bubble Shot"))
					"wep_grav_gun":
						show_prompt(["wep_3"], tr("Gravity Cannon"))
					"wep_time_gun":
						show_prompt(["wep_4"], tr("Time Gun"))
		else:
			player.gun.remove_weapon(item)
	elif player.current_weapon == item:
		$gameing/weapon/ammo/ammo_label.text = str(count)
		if player.current_weapon and !$gameing/weapon.visible:
			show_ammo()
	else:
		match item:
			"health_up":
				var health_up := count
				var h_factor = (1.0 + player.HEALTH_UP_BOOST*health_up)
				player.max_health = player.DEFAULT_MAX_HEALTH*h_factor
				health_bar.max_value = player.max_health
				health_bar.rect_min_size.x = player.HEALTH_BAR_DEFAULT_SIZE*h_factor
			"stamina_up":
				var stamina_up := count
				var s_factor = (1.0 + player.STAMINA_UP_BOOST*stamina_up)
				player.max_stamina = player.DEFAULT_MAX_STAMINA*s_factor
				stamina_bar.max_value = player.max_stamina
				stamina_bar.rect_min_size.x = player.STAMINA_BAR_DEFAULT_SIZE*s_factor
			"jump_height_up":
				player.jump_factor = (1 + player.JUMP_UP_BOOST*count)
			"move_speed_up":
				player.speed_factor = (1 + player.SPEED_UP_BOOST*count)
			"move_speed_up":
				player.stamina_drain_factor = (1 + player.SPEED_STAMINA_BOOST*count)
			"damage_up":
				var damage_up_count := count
				player.damage_factor = (1 + player.DAMAGE_UP_BOOST*damage_up_count)
				player.max_damage = damage_up_count >= player.MAX_DAMAGE_UP
			"armor":
				var new_armor:int = count
				if new_armor > player.armor:
					player.extra_health += (new_armor - player.armor)*player.ARMOR_BOOST
				player.armor = new_armor
				armor_bar.rect_min_size.x = player.ARMOR_BAR_DEFAULT_SIZE*player.armor
				armor_bar.visible = player.armor > 0 and player.extra_health > 0
				update_health()
			"stamina_booster":
				var new_energy := count
				if new_energy > player.energy:
					player.extra_stamina = new_energy*player.EXTRA_STAMINA_BOOST
				player.energy = new_energy
				energy_bar.visible = player.energy > 0
			"hover_speed_up":
				player.hover_speed_factor = 1.0 + player.HOVER_SPEED_BOOST*count
			"hover_scooter":
				if !startup:
					show_prompt(["hover_toggle"], "Use hover-scooter")
			_:
				var old_item_count := equipment_inventory.size()
				if ResourceLoader.exists(equipment_path_f % item):
					if count <= 0 and item in equipment_inventory:
						if equipment_inventory[item] == player.equipped_item:
							if equipment_inventory.size() > 1:
								equip_previous()
							elif player.equipped_item:
								player.equipped_item.unequip()
								player.equipped_item = null
						var _x = equipment_inventory.erase(item)
					elif count > 0 and !(item in equipment_inventory):
						var s: Script = ResourceLoader.load(equipment_path_f % item)
						if s:
							equipment_inventory[item] = s.new()
							if player.equipped_item:
								player.equipped_item.unequip()
							player.equipped_item = equipment_inventory[item]
							player.equipped_item.equip()
							update_equipment()
				if !startup and equipment_inventory.size() > old_item_count:
					if equipment_inventory.size() == 1:
						show_prompt(["use_item"], tr("Use Item"))
					else:
						show_prompt(["choose_item"], tr("(Hold) Swap Item"))

func on_journal_updated(category: String, subject: String):
	var alert = [category.capitalize(), subject.capitalize()]
	$gameing/note_get.show_alert(alert)
	$dialog/note_get.show_alert(alert)

func equip_previous():
	if equipment_inventory.size() == 1:
		return update_equipment()
	else:
		var index = equipment_inventory.values().find(player.equipped_item)
		equip(index - 1)

func equip_next():
	if equipment_inventory.size() == 1:
		return update_equipment()
	else:
		var index = equipment_inventory.values().find(player.equipped_item)
		equip(index + 1)

func equip(index):
	if equipment_inventory.size() == 0:
		return
	if player.equipped_item:
		player.equipped_item.unequip()
	var ln = equipment_inventory.size()
	while index < 0:
		index += ln
	while index >= ln:
		index -= ln
	player.equipped_item = equipment_inventory.values()[index]
	player.equipped_item.equip()
	update_equipment()

func update_equipment():
	var values = equipment_inventory.values()
	var index = values.find(player.equipped_item)
	if index >= 0:
		equipment.temp_show()
		var prev_index = index - 1
		var next_index = index + 1
		var ln = values.size()
		if prev_index < 0:
			prev_index += ln
		if next_index >= ln:
			next_index -= ln
		equipment.preview(values[index], values[prev_index], values[next_index])

func show_inventory():
	for g in $gameing/inventory.get_children():
		if g is CanvasItem:
			g.visible = true
	$gameing/inventory.show()
	$gameing/inventory/vis_timer.start()
	show_ammo()
	update_equipment()

func show_specific_item(item):
	if !$gameing/inventory.visible:
		for g in $gameing/inventory.get_children():
			if g is CanvasItem:
				g.visible = false
		$gameing/inventory.show()
	$gameing/inventory/vis_timer.start()
	var count = get_node("gameing/inventory/"+item+"_count")
	var icon = get_node("gameing/inventory/"+item+"_icon")
	var added = get_node("gameing/inventory/"+item+"_added")
	if !icon or !count or !added:
		print_debug("BUG: no inventory for ", item)
		return
	added.show()
	icon.show()
	count.show()

func _on_vis_timer_timeout():
	$gameing/inventory.hide()
	if player.gun.state == Gun.State.Hidden:
		hide_ammo()
		
func show_ammo():
	if player.current_weapon and player.current_weapon != "":
		$gameing/weapon.show()

func hide_ammo():
	$gameing/weapon.hide()

func add_label(box: Control, text: String):
	var l := Label.new()
	l.text = text
	box.add_child(l)

func debug_show_inventory():
	var state_viewer: Control = $gameing/debug/game_state
	for c in state_viewer.get_children():
		state_viewer.remove_child(c)
	add_label(state_viewer, "Inventory:")
	for i in Global.game_state.inventory:
		add_label(state_viewer, "\t%s: %d" % [i, Global.count(i)])

func prepare_save():
	$gameing/saveStats/AnimationPlayer.play("save_start")

func complete_save():
	$gameing/saveStats/AnimationPlayer.queue("save_complete")

func start_dialog(source: Node, sequence: Resource, speaker: Node, starting_label := ""):
	set_mode(Mode.Dialog)
	dialog.start(source, sequence, speaker, starting_label)

func in_dialog():
	return mode == Mode.Dialog

func set_mode(m):
	if m < 0 or m >= get_child_count():
		print_debug("Bad mode! ", m)
		return
	
	var should_pause: bool = (m == Mode.Paused or m == Mode.DebugConsole)
	if !should_pause:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var toggled_pause := false
	if should_pause and !get_tree().paused:
		toggled_pause = true
		mode_before_pause = mode
	get_tree().paused = should_pause
	
	if should_pause and $story_time.queued_story:
		m = Mode.StoryTime
		$story_time.start_countdown()
	
	if m != Mode.Paused:
		Global.get_player().set_camera_render(true)
	elif toggled_pause:
		take_screen_shot()

	mode = m
	var i = 0
	for c in get_children():
		if !(c is Control):
			continue
		c.visible = i == mode
		i += 1

func show_prompt(actions: Array, text: String):
	$gameing/tutorial/prompt_timer.stop()
	if actions.size() >= 1:
		$gameing/tutorial/input_prompt.show()
		$gameing/tutorial/input_prompt.action = actions[0]
	else:
		$gameing/tutorial/input_prompt.hide()
	if actions.size() >= 2:
		$gameing/tutorial/plus.show()
		$gameing/tutorial/input_prompt2.show()
		$gameing/tutorial/input_prompt2.action = actions[1]
	else:
		$gameing/tutorial/plus.hide()
		$gameing/tutorial/input_prompt2.hide()

	$gameing/tutorial/Label.text = text
	$gameing/tutorial.show()
	$gameing/tutorial/prompt_timer.start()

func hide_prompt():
	$gameing/tutorial.hide()
	$gameing/tutorial/prompt_timer.stop()

func _on_prompt_timer_timeout():
	$gameing/tutorial.hide()

func take_screen_shot():
	Global.get_player().set_camera_render(true)
	hide()
	get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	yield(VisualServer, "frame_post_draw")
	var screen = get_viewport().get_texture().get_data()
	var stex = ImageTexture.new()
	stex.create_from_image(screen)
	$status_menu/TextureRect.texture = stex
	show()
	Global.get_player().set_camera_render(false)

func show_status() -> bool:
	set_mode(Mode.Paused)
	return true

func unpause() -> bool:
	$post_pause_timer.start()
	set_mode(mode_before_pause)
	return true

func recently_paused():
	return !$post_pause_timer.is_stopped()

func play_game() -> bool:
	set_mode(Mode.Gameing)
	return true

func open_custom(scene: PackedScene) -> bool:
	if !scene:
		return false

	if loaded_ui == scene:
		set_mode(Mode.Custom)
		return true

	var cui := scene.instance() as Control
	if !cui:
		return false

	if custom_ui:
		remove_child(custom_ui)
		custom_ui.queue_free()
	custom_ui = cui
	add_child(custom_ui)

	if custom_ui.has_signal("exited"):
		var _x = custom_ui.connect("exited", self, "play_game")
	
	loaded_ui = scene
	
	set_mode(Mode.Custom)
	return true
