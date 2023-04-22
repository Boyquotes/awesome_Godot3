extends KinematicBody
class_name FollowerNPC

#signal npc_event(event_type)

enum MetaState {
	# Not doing anything
	Idle,
	# Fighting enemies
	Combat,
	# Following the player
	Follow,
	# Travelling somewhere
	TravelTo,
	# Travelling, but waiting for the player
	TravelWaiting,
	# Observing an object from a specific position
	ObservePoint,
	# Play a contextual animation
	Act 
}

var velocity := Vector3.ZERO
var meta_state = MetaState.Idle
var target : Spatial
var entry_next: NodePath
var player: PlayerBody
var location := ""

export(String) var friendly_id := ""
export(float) var player_distance_while_travelling := 14.0 setget set_pdwt
export(float) var travel_resume := 90.0
export(bool) var default_location := false
var turn_speed := 15.0
var pdwt_sq : float

onready var dialog:DialogTrigger = $dialog_zone

func _ready():
	var chunk = get_chunk()
	var sc = stat("chunk")
	if !(sc is String):
		sc = ""
	if !(default_location and sc == "") and sc != chunk:
		queue_free()
		return

	set_pdwt(player_distance_while_travelling)
	player = Global.get_player()
	set_mstate(MetaState.Idle)
	if has_stat("location"):
		var loc = stat("location")
		if has_node(loc):
			var l = get_node(loc)
			location = l.name
			if l is Spatial:
				global_transform.origin = l.global_transform.origin
			else:
				print_debug("Not spatial: ", l.get_path())
		else:
			print_debug("Doesn't exist: ", loc)
	if get_parent().name == "active_entities":
		call_deferred("extract")

func extract():
	# TODO: probably the opposite
	var p = get_parent()
	var gp = p.get_parent()
	var t = global_transform
	p.remove_child(self)
	gp.add_child(self)
	global_transform = t

func _physics_process(delta):
	match meta_state:
		MetaState.TravelTo:
			if !target:
				set_mstate(MetaState.Idle)
				return
			
			var pos = target.global_transform.origin
			var ppos = pos - player.global_transform.origin
			var dir = pos - global_transform.origin
			var pdist = player.global_transform.origin - global_transform.origin
			
			if pdist.length_squared() > pdwt_sq and ppos.length_squared() > dir.length_squared() + travel_resume:
				set_mstate(MetaState.TravelWaiting)
			else:
				$nav_pointer/final.global_transform = $nav_pointer/final.global_transform.looking_at(pos, Vector3.UP)
				dir.y = 0
				if dir.length() < 0.2:
					get_next_point()
				else:
					var vy = velocity.y
					velocity = dir.normalized()*9
					velocity.y = vy
				if target and target.action != NavPoint.Action.None:
					var look_dir := target.global_transform.basis.z
					look_dir.y = 0
					var angle := global_transform.basis.z.angle_to(look_dir)
					if angle > 0.01:
						var axis := global_transform.basis.z.cross(look_dir).normalized()
						if axis.is_normalized():
							var turn = sign(angle)*min(turn_speed*delta, abs(angle))
							global_rotate(axis, turn)
		MetaState.TravelWaiting:
			velocity.x = 0
			velocity.z = 0
			
			var pos = target.global_transform.origin
			var ppos = pos - player.global_transform.origin
			var dir = pos - global_transform.origin
			var pdist = player.global_transform.origin - global_transform.origin
			
			if pdist.length_squared() < pdwt_sq - travel_resume or ppos.length_squared() < dir.length_squared() - travel_resume:
				set_mstate(MetaState.TravelTo)
	velocity = move_and_slide(velocity + Vector3.DOWN*24*delta)

func set_pdwt(pdwt):
	player_distance_while_travelling = pdwt
	pdwt_sq = pdwt*pdwt

func at(place):
	return location == place

func get_next_point():
	if target and "action" in target and "next" in target:
		location = target.name
		set_stat("location", target.get_path())
		if target.action == NavPoint.Action.Jump:
			velocity += target.global_transform.basis.z*5 + Vector3.UP*5
		elif target.action == NavPoint.Action.OpenDoor:
			for c in $door_hitbox.get_overlapping_bodies():
				if c.has_method("take_damage"):
					c.take_damage(0, global_transform.basis.z, self)
		if target.chunk_entry:
			var t = target.chunk_entry.split(":")
			assert(t.size() == 2)
			var chunk_name = t[0]
			entry_next = t[1]
			var world = get_tree().current_scene
			target = world.get_node(chunk_name)
			
			if world.is_active(chunk_name):
				_on_chunk_activated(target)
			else:
				if !world.is_connected("activated", self, "_on_chunk_activated"):
					world.connect("activated", self, "_on_chunk_activated")
		elif target.has_node(target.next):
			target = target.get_node(target.next)
		else:
			target = null
			entry_next = ""

func _on_chunk_activated(chunk):
	if chunk == target:
		var world = get_tree().current_scene
		var d = world.get_dynamic_content(chunk.name)
		var gt = global_transform
		get_parent().remove_child(self)
		d.add_child(self)
		global_transform = gt
		assert(d.has_node(entry_next))
		target = d.get_node(entry_next)
		entry_next = ""
		set_stat("chunk", chunk.name)
		
		if world.is_connected("activated", self, "_on_chunk_activated"):
			world.disconnect("activated", self, "_on_chunk_activated")
	
func travel_to(_place:String, custom_exit := ""):
	if has_node(custom_exit):
		target = get_node(custom_exit)
	else:
		print_debug("NO NODE TO: ", custom_exit, " FROM ", get_path())
		return
	dialog.enabled = false
	print("travelling to ", target.get_path())
	set_mstate(MetaState.TravelTo)

func set_mstate(new_mstate):
	meta_state = new_mstate
	set_physics_process(meta_state != MetaState.Idle)
	$dialog_zone.enabled = meta_state == MetaState.Idle

func set_stat(stat: String, value):
	return Global.set_stat(friendly_id + "/" + stat, value)

func stat(stat: String):
	return Global.stat(friendly_id + "/" + stat)

func has_stat(stat: String):
	return Global.has_stat(friendly_id + "/" + stat)

func get_chunk() -> String:
	var p = get_parent()
	while p and !(p is Chunk):
		p = p.get_parent()
	if p is Chunk:
		p = p.get_parent()
	return p.name if p else ""

func continue_travel(starting_node: String):
	if has_node(location):
		target = get_node(location)
	elif has_node(starting_node):
		target = get_node(starting_node)
	dialog.enabled = false
	set_mstate(MetaState.TravelTo)
