extends Spatial

signal activated(chunk)
signal deactivated(chunk)

export(Dictionary) var preloaded_chunks: Dictionary
export(Dictionary) var preloaded_lowres: Dictionary

var air_tutorial := false

# Distance from the bounding box edge
const DIST_LOAD := 500
const DIST_UNLOAD := 550
const DIST_ACTIVATE := 150
const DIST_DEACTIVATE := 175

const UNLOAD_TIME := 10.0

var chunks: Dictionary
var lowres_chunks: Dictionary
#var chunk_collider: Dictionary

const CHUNK_SQDIST_UPDATE := 17
const VIS_SQDIST_UPDATE := 1
const ACTIVE_SQDIST_UPDATE := 19
const ENEMIES_SQDIST_UPDATE := 9

onready var player: PlayerBody = $player
onready var chunk_last_position: Vector3 = player.global_transform.origin
onready var active_last_position : Vector3 = player.global_transform.origin
onready var vis_last_position :Vector3 = player.global_transform.origin
onready var enemies_last_position :Vector3 = player.global_transform.origin

var enemies_present := false
var MIN_DIST_SQ_ENEMIES := 2000.0

onready var env := $WorldEnvironment
onready var env_tween: Tween = $env_tween
onready var sun_tween: Tween = $sun_tween
onready var sun := $sun
onready var indirect_tween := $indirect_tween
onready var wind := $audio_wind
var sun_enabled := true

onready var env_settings := $env_settings
var env_overrides: Array
var shaders_ready := false

var time := 0.0
var TIME_READY := 0.5

const FOG_TWEEN_TIME := 2.5

const DIST_HIRES := 1500.0
const DIST_LOWRES := 2000.0

const BEDTIME := 21.00
const TOO_EARLY := 4.00
const RISE_AND_SHINE := 6.00

var terrain_hires: Dictionary
var terrain_lowres: Dictionary

var chunk_loader: ChunkLoader
var ignore_day := false

func _init():
	preloaded_chunks = {}
	preloaded_lowres = {}
	terrain_hires = {}
	terrain_lowres = {}
	env_overrides = []

func _input(event):
	if event.is_action_pressed("debug_map_view"):
		if $mapcam.current:
			player.ui.show()
			player.cam_rig.camera.current = true
		else:
			player.hide()
			$mapcam.current = true

func _enter_tree():
	if !Global.valid_game_state and ResourceLoader.exists(Global.save_path):
		Global.load_sync(false)
		
func _exit_tree():
	chunk_loader.quit()
		
func _ready():
	var _x = env_tween.start()
	if false:
		print("Random races")
		for _i in range (10):
			print("\t", int(rand_range(0, 144)))
		print("Random jump game")
		for _i in range (15):
			print("\t", int(rand_range(0, 144)))
		print("Riley")
		for _i in range (10):
			print("\t", int(rand_range(0, 144)))
	
	chunk_loader = ChunkLoader.new()
	print("Readying world...")
	#_x = chunk_loader.connect("load_start", self, "_on_load_started")
	#_x = chunk_loader.connect("load_complete", self, "_on_load_complete")
	
	for c in get_children():
		if c.name.begins_with("chunk_lowres"):
			var name_convert = c.name.replace("chunk_lowres", "chunk").replace("000", "")
			terrain_lowres[name_convert] = c.mesh
			c.queue_free()
		elif c.name.begins_with("chunk"):
			terrain_hires[c.name] = c.mesh
			chunks[c.name] = c

	print("Collected meshes")
	#load_everything()
	# Briefly render the opposite light
	sun.visible = !sun_enabled
	chunk_last_position = player.global_transform.origin
	active_last_position = player.global_transform.origin
	start_loading_chunks()
	load_nearby_chunks(player.global_transform.origin)
	update_active_chunks(chunk_last_position)
	
	vis_last_position = player.global_transform.origin
	update_terrain_lod(vis_last_position)
	if Global.valid_game_state:
		if Global.has_stat("clock_time"):
			set_time(Global.stat("clock_time"), true)
	else:
		set_time(9.75)
	

func _process(delta):
	time += delta
	if !shaders_ready and time > TIME_READY:
		sun.visible = sun_enabled
		sun.light_energy = 1.0 if sun_enabled else 0.0
		shaders_ready = true
	var player_new_position = player.global_transform.origin
	#apply_fog(player_new_position.y)
	if (chunk_last_position - player_new_position).length_squared() >= CHUNK_SQDIST_UPDATE:
		load_nearby_chunks(player_new_position)
		chunk_last_position = player_new_position
		if chunk_last_position.y < -8000:
			player.fall_to_death()
	if (active_last_position - player_new_position).length_squared() >= ACTIVE_SQDIST_UPDATE:
		update_active_chunks(player_new_position)
		active_last_position = player_new_position
	if (enemies_last_position - player_new_position).length_squared() >= ENEMIES_SQDIST_UPDATE:
		enemies_last_position = player_new_position
		detect_enemies(delta)
	if (vis_last_position - player_new_position).length_squared() >= VIS_SQDIST_UPDATE:
		vis_last_position = player_new_position
		get_tree().call_group("distance_activated", "process_player_distance", player_new_position)
		update_terrain_lod(vis_last_position)

func get_sun():
	return sun

func prepare_save():
	Global.set_stat("clock_time", get_time())

func update_terrain_lod(pos: Vector3):
	pos.y = 0
	for c in chunks.values():
		if !(c.name in terrain_lowres and c.name in terrain_hires):
			continue
		var d = (c.global_transform.origin - pos).length_squared()
		if d > DIST_LOWRES*DIST_LOWRES:
			if c.mesh != terrain_lowres[c.name]:
				c.mesh = terrain_lowres[c.name]
		elif d < DIST_HIRES*DIST_HIRES:
			if c.mesh != terrain_hires[c.name]:
				c.mesh = terrain_hires[c.name]

func start_loading_chunks():
	# Sort the chunks by distance from player
	var sorted_chunks := chunks.values()
	sorted_chunks.sort_custom(self, "compare_distances")
	chunk_loader.add_preloaded(sorted_chunks, preloaded_chunks, preloaded_lowres)
	#var _x = chunk_loader.first_complete.wait()

func _on_load_started():
	$loading.show()

func _on_load_complete():
	chunk_loader.quit()
	$loading.hide()

func compare_distances(a: Spatial, b: Spatial):
	var dist_a = (chunk_last_position - a.global_transform.origin).length_squared()
	var dist_b = (chunk_last_position - b.global_transform.origin).length_squared()
	return dist_a < dist_b

func detect_enemies(_delta):
	var were_present := enemies_present
	enemies_present = false
	var air_enemies_present = false
	var cloaked_enemies_present = false
	for e in get_tree().get_nodes_in_group("enemy"):
		var dist_squared: float = e.process_player_distance(player.global_transform.origin)
		if dist_squared < MIN_DIST_SQ_ENEMIES:
			if "can_fly" in e and e.can_fly:
				air_enemies_present = true
			elif e.cloaked:
				cloaked_enemies_present = true
			else:
				enemies_present = true
	
	Music.in_combat = enemies_present
	if cloaked_enemies_present and Global.count("wep_pistol") and !Global.stat("cloaked_combat_tutorial"):
		show_cloaked_combat_tutorial()
	if air_enemies_present and !Global.stat("air_combat_tutorial"):
		show_air_combat_tutorial()
	elif !were_present and enemies_present and !Global.stat("combat_tutorial"):
		show_combat_tutorial()

func load_nearby_chunks(position: Vector3):
	for ch in chunks.values():
		var local : Vector3 = position - ch.global_transform.origin
		var load_zone: AABB = ch.get_aabb().grow(Global.render_distance*DIST_LOAD)
		var unload_zone:AABB = ch.get_aabb().grow(Global.render_distance*DIST_UNLOAD)
		
		if load_zone.has_point(local) and !chunk_loader.is_loaded(ch.name):
			chunk_loader.queue_load(ch, false)
			emit_signal("activated", ch)
		elif !unload_zone.has_point(local) and chunk_loader.is_loaded(ch.name):
			chunk_loader.queue_unload(ch)
			emit_signal("deactivated", ch)

func update_active_chunks(position: Vector3):
	var active_box = $debug/box/active_chunks
	active_box.text = "Active Chunks:"
	for ch in chunks.values():
		if !chunk_loader.is_loaded(ch.name):
			continue
		var local : Vector3 = position - ch.global_transform.origin
		var activate_zone:AABB = ch.get_aabb().grow(Global.render_distance*DIST_ACTIVATE)
		var deactivate_zone:AABB = ch.get_aabb().grow(Global.render_distance*DIST_DEACTIVATE)
		
		if activate_zone.has_point(local):
			chunk_loader.activate(ch)
		elif !deactivate_zone.has_point(local):
			chunk_loader.deactivate(ch)

func show_combat_tutorial():
	var _x = Global.add_stat("combat_tutorial")
	player.ui.show_prompt(["combat_lunge"], "Lunge Kick")
	air_tutorial = false
	$tutorial_swap.start()

func show_cloaked_combat_tutorial():
	var _x = Global.add_stat("cloaked_combat_tutorial")
	if Global.using_gamepad:
		player.ui.show_prompt(["combat_aim_toggle"], "Toggle aim")
	else:
		player.ui.show_prompt(["combat_aim"], "Aim")

func show_air_combat_tutorial():
	var _x = Global.add_stat("air_combat_tutorial")
	player.ui.show_prompt(["mv_crouch", "combat_lunge"], "Uppercut")
	air_tutorial = true
	$tutorial_swap.start()

func _on_tutorial_swap_timeout():
	if air_tutorial:
		player.ui.show_prompt(["mv_jump", "combat_lunge"], "Diving Kick")
	else:
		player.ui.show_prompt(["combat_spin"], "Spin Kick")

# Environment
func apply_environment(p_env: Dictionary):
	var insert_index := env_overrides.size()
	for i in range(env_overrides.size()):
		if p_env.priority >= env_overrides[i].priority:
			insert_index = i
			break
	if insert_index > 0:
		# Not enabled right now
		env_overrides.insert(insert_index, p_env)
		return
	env_overrides.push_front(p_env)
	_set_env(p_env)

func remove_environment(id:int):
	var remove_index := -1
	for i in range(env_overrides.size()):
		if env_overrides[i].id == id:
			remove_index = i
	if remove_index < 0:
		# Not found
		return
	elif remove_index == 0:
		# Set next in list or clear env
		var _renv = env_overrides.pop_front()
		if !env_overrides.empty():
			_set_env(env_overrides[0])
		else:
			_clear_env()
	else:
		# just remove it from the list
		env_overrides.remove(remove_index)

func _set_env(p_env: Dictionary):
	$env_settings.active_overrides = p_env.keys()
	if "wind_reduction_db" in p_env:
		wind.apply_volume(-p_env.wind_reduction_db)
	else:
		wind.apply_volume(0.0)
	if "custom_fog" in p_env:
		set_fog_override(p_env.custom_fog, p_env.fog_start, p_env.fog_end)
	else:
		clear_fog_override()
	if "indirect_light" in p_env:
		indirect_light_override(p_env.indirect_light)
	else:
		clear_indirect_light()
	if "default_music" in p_env and "combat_music" in p_env:
		Music.set_music(p_env.default_music, p_env.combat_music)
	else:
		Music.reset()
	if "show_sun" in p_env:
		set_sun_enabled(p_env.show_sun)
	else:
		set_sun_enabled(env_settings.sun_visible)
	var p = Global.get_player()
	if "do_not_disturb" in p_env:
		p.do_not_disturb = p_env.do_not_disturb
	else:
		p.do_not_disturb = false
	if "close_cam" in p_env:
		p.cam_rig.set_close_cam(p_env.close_cam)
	else:
		p.cam_rig.set_close_cam(false)

func _clear_env():
	_set_env({})

func get_wind_audio():
	return $audio_wind

func set_sun_enabled(enabled:bool):
	sun_enabled = enabled
	if time < TIME_READY:
		sun.light_energy = 1.0 if !enabled else 0.0
		sun.visible = !enabled
		return
		
	var _x = sun_tween.remove_all()
	_x = sun_tween.interpolate_property(sun, "light_energy",
		sun.light_energy,
		1.0 if enabled else 0.0,
		FOG_TWEEN_TIME,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	
	if !enabled and sun.visible:
		_x = sun_tween.interpolate_callback(sun, 
			FOG_TWEEN_TIME + 0.1, "hide")
	elif enabled:
		if !sun.visible:
			sun.light_energy = 0
		sun.show()
	_x = sun_tween.start()

func indirect_light_override(light: Color):
	var _x = indirect_tween.stop_all()
	if time < TIME_READY:
		env.environment.indirect_light_color = light
		return
	_x = indirect_tween.remove_all()
	_x = indirect_tween.interpolate_property(env.environment, "indirect_light_color",
		env.environment.indirect_light_color, light,
		FOG_TWEEN_TIME, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_x = indirect_tween.start()

func clear_indirect_light():
	indirect_light_override(env_settings.indirect_light_color)

func set_fog_override(fog: Color, begin: float, end:float):
	var _x = env_tween.stop_all()
	if time < TIME_READY:
		env.environment.fog_color = fog
		env.environment.fog_depth_begin = begin
		env.environment.fog_depth_end = end
		return
	_x = env_tween.remove_all()
	_x = env_tween.interpolate_property(env.environment, "fog_color",
		env.environment.fog_color, fog,
		FOG_TWEEN_TIME,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_x = env_tween.interpolate_property(env.environment, "fog_depth_begin",
		env.environment.fog_depth_begin, begin,
		FOG_TWEEN_TIME,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_x = env_tween.interpolate_property(env.environment, "fog_depth_end",
		env.environment.fog_depth_end, end,
		FOG_TWEEN_TIME,
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_x = env_tween.start()

func clear_fog_override():
	set_fog_override(
		env_settings.fog_color,
		env_settings.fog_depth_begin,
		env_settings.fog_depth_end)

func is_active(chunk_name):
	return chunk_loader.is_loaded(chunk_name)

func get_dynamic_content(chunk_name):
	return get_node(chunk_name).get_node("dynamic_content")

## Day/night cycle

func sleep():
	chunk_loader.unload_all()
	var t = get_time()
	if t > BEDTIME or t < TOO_EARLY:
		set_time(RISE_AND_SHINE, false)
	else:
		set_time(get_time() + 2, false)

func wake_up():
	start_loading_chunks()
	load_nearby_chunks(player.global_transform.origin)
	update_active_chunks(player.global_transform.origin)

func start_day():
	if !ignore_day:
		print("Brand new day!")
		var _x = Global.add_stat("current_day")
		get_tree().call_group("daily_schedule", "_on_midnight")
	else:
		print("Day ignored!")
	ignore_day = false

# Hours with decimals
func get_time():
	# Seconds of animation (600 for 24-hour day)
	var hours_per_second := 1.0/25.0
	# Offset in the animation to midnight
	var midnight_offset := 330.0
	var sec_time:float = $day_night.current_animation_position
	var hour := hours_per_second * (sec_time - midnight_offset)
	while hour < 0.0:
		hour += 24.0
	while hour > 24.0:
		hour -= 24.0
	return hour

func set_time(hour: float, p_ignore_day := true):
	var dn := $day_night
	
	var seconds_per_hour := 25.0
	var midnight_offset := 330.0
	var animation_length := 600.0
	var current_time = dn.current_animation_position
	var seconds := seconds_per_hour*hour + midnight_offset
	while seconds < 0.0:
		seconds += animation_length
		
	ignore_day = p_ignore_day
	print("Set time to ", hour, " ignore day: ", p_ignore_day)
	if seconds < current_time:
		dn.stop()
		dn.play("day_night_normal")
		dn.advance(seconds/dn.playback_speed)
	else:
		dn.advance((seconds - current_time)/dn.playback_speed)
	sun.call_deferred("update_rotation")
