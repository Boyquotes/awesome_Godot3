extends Weapon

const BASE_DAMAGE := 5.0
const BASE_RANGE := 60.0

onready var cast_start := $cast_start
onready var impact := $impact/Particles

func _init():
	time_firing = 0.15

func fire() -> bool:
	if !Global.count("pistol"):
		$AnimationPlayer.play("dry_fire")
		return false
	var _x = Global.add_item("pistol", -1)
	$AnimationPlayer.play('fire')
	# Cast damage ray
	var space: RID = get_world().space
	var ds := PhysicsServer.space_get_direct_state(space)
	var start: Vector3 = cast_start.global_transform.origin
	var end: Vector3 = start + cast_start.global_transform.basis.z*BASE_RANGE
	var collision := ds.intersect_ray(start, end, [], Gun.MASK_ATTACK)
	if "collider" in collision:
		var collider = collision.collider
		if collider.has_method("take_damage"):
			collider.take_damage(BASE_DAMAGE, cast_start.global_transform.basis.z, Global.get_player())
			if collider.has_method("aggro_to"):
				collider.aggro_to(Global.get_player())
		impact.emitting = false
		impact.global_transform.origin = collision.position
		impact.emitting = true
		Bumps.impact_on(collider, Bumps.Impact.ImpactStrong, collision.position, collision.normal)
	return true

func combo_fire():
	var _x = $AnimationPlayer.connect("animation_finished", self, "_combo_fire_mid", [], CONNECT_ONESHOT)
	return fire()

func _combo_fire_mid(_a):
	var _x = fire()

func unholster():
	show()
	$AnimationPlayer.play("RESET")
