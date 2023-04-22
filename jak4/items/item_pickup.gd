tool
extends KinematicBody
class_name ItemPickup

signal gravity_stun(stun)
signal picked
signal picked_item(id)

export(String) var item_id
export(int) var quantity := 1
export(PackedScene) var preview
export(bool) var persistent := true
export(bool) var gravity = false
export(String) var friendly_name = ""
export(bool) var from_kill := false
export(AudioStream) var custom_sound
export(bool) var emit_signal_at_ready := false
export(bool) var celebrate := false

const sq_distance_visible := 100*100
const sq_distance_animated := 50*50

var gravity_stun_time := 0.0
var fall_velocity := 0.0

var anim: AnimationPlayer
var sub_anim : AnimationPlayer

func _ready():
	if preview:
		var p = preview.instance()
		add_child(p)
		p.name = "preview"
	if Engine.editor_hint:
		return
	if persistent and Global.is_picked(get_path()):
		if emit_signal_at_ready:
			pick()
		else:
			queue_free()
		return
	if from_kill:
		$area/CollisionShape.disabled = true
		$pickup_timer.start()
	if has_node("AnimationPlayer"):
		anim = $AnimationPlayer
		anim.seek(rand_range(0, anim.current_animation_length))
	if has_node("bug/AnimationPlayer"):
		sub_anim = $bug/AnimationPlayer
		sub_anim.seek(rand_range(0, sub_anim.current_animation_length))
	set_physics_process(gravity)

func _physics_process(delta):
	if gravity:
		if gravity_stun_time > 0:
			gravity_stun_time -= delta
			fall_velocity *= clamp(1.0 - delta, 0.1, 0.995)
			fall_velocity += delta*Global.gravity_stun_velocity
			if gravity_stun_time <= 0:
				emit_signal("gravity_stun", false)
		else:
			fall_velocity -= 9.8*delta
		var col = move_and_collide(delta*Vector3.UP*fall_velocity)
		if col:
			fall_velocity = 0.0
	else:
		set_physics_process(false)

func _on_area_body_entered(body):
	var _x = Global.add_item(item_id, quantity)
	body.get_item(self)
	if persistent:
		Global.mark_picked(get_path())
		if friendly_name != "":
			_x = Global.add_stat(friendly_name)
	pick()

func pick():
	emit_signal("picked")
	emit_signal("picked_item", item_id)
	queue_free()

func gravity_stun(_damage):
	gravity = true
	gravity_stun_time = Global.gravity_stun_time
	fall_velocity = 3
	emit_signal("gravity_stun", true)
	set_physics_process(true)

func process_player_distance(origin: Vector3):
	var gr2 = Global.render_distance*Global.render_distance
	var sq_dist = (origin - global_transform.origin).length_squared()
	var vis:bool = sq_dist < gr2*sq_distance_visible
	var animated: bool = sq_dist < gr2*sq_distance_animated
	if visible != vis:
		visible = vis
		set_physics_process(vis)
	if anim and animated != anim.is_playing():
		if animated:
			anim.play()
		else:
			anim.stop(false)
		if sub_anim:
			if animated:
				sub_anim.play()
			else:
				sub_anim.stop(false)
	return INF

func _on_pickup_timer_timeout():
	$area/CollisionShape.disabled = false
