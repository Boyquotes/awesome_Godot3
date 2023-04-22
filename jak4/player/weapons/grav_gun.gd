extends Weapon

# On fire, launches the explosive.
# If fire is held for more than 0.25 seconds, it explodes on release
# Otherwise it explodes on contact.
# Just for the sake of it, it uses object pooling

onready var launcher := $launcher
onready var projectile := $launcher/projectile
onready var explosion := $launcher/explosion
onready var sound := $launcher/explode_sound
onready var scene = get_tree().current_scene

var proj_pool : Array
var expl_pool : Array
var sound_pool : Array

func _init():
	time_firing = 0.35

func _ready():
	explosion.make_unique()
	projectile.get_parent().remove_child(projectile)
	explosion.get_parent().remove_child(explosion)
	sound.get_parent().remove_child(sound)
	proj_pool.append(projectile)
	expl_pool.append(explosion)
	sound_pool.append(sound)

func _enter_tree():
	if has_node("fire_sound"):
		$fire_sound.stop()

func fire() -> bool:
	if !Global.count("grav_gun"):
		# TODO dry fire
		return false
	var _x = Global.add_item("grav_gun", -1)
	$fire_sound.play()
	# TODO animation
	var new_proj: Spatial
	if proj_pool.empty():
		new_proj = projectile.duplicate()
	else:
		new_proj = proj_pool.pop_back()
	scene.add_child(new_proj)
	new_proj.global_transform = launcher.global_transform
	new_proj.fire(launcher.global_transform.basis.z)
	new_proj.apply_central_impulse(new_proj.mass*Global.get_player().velocity)

	return true

func _on_projectile_contact(proj: Spatial):
	var pos := proj.global_transform.origin
	proj.get_parent().remove_child(proj)
	proj_pool.append(proj)
	
	var new_expl: Spatial
	var new_sound: AudioStreamPlayer3D

	var was_created := false
	if expl_pool.empty():
		new_expl = explosion.duplicate()
		was_created = true
	else:
		new_expl = expl_pool.pop_back()
		new_expl.request_ready()
	
	scene.add_child(new_expl)
	if was_created:
		new_expl.make_unique()
	new_expl.global_transform.origin = pos
	
	if sound_pool.empty():
		new_sound = sound.duplicate()
	else:
		new_sound = sound_pool.pop_back()
	scene.add_child(new_sound)
	new_sound.global_transform.origin = pos
	new_sound.play()

func _on_explosion_disappeared(expl: Spatial):
	expl.get_parent().remove_child(expl)
	expl_pool.append(expl)

func _on_explode_sound_finished(node):
	node.get_parent().remove_child(node)
	sound_pool.append(node)

func combo_fire():
	return fire()
