extends Node

enum Surface {
	Sand,
	Rock,
	Metal,
	Glass,
	Grass,
	Wood
}

enum Impact {
	Footstep,
	ImpactLight,
	ImpactStrong,
	SlidingStep,
	SlidingImpact
}

onready var emitters := {
	Surface.Sand: {
		Impact.ImpactLight:$particle_sand_small,
		Impact.ImpactStrong:$particle_sand_large,
	},
	Surface.Rock: {
		Impact.ImpactLight:$particle_sand_small,
		Impact.ImpactStrong:$particle_sand_large,
	}
}

onready var audio_players := {
	Impact.Footstep:$sound_footstep,
	Impact.ImpactLight:$sound_footstep
}

var low_rock_sounds := [
	preload("res://audio/player/stepdirt1.wav"),
	preload("res://audio/player/stepdirt2.wav"),
	preload("res://audio/player/stepdirt3.wav"),
	preload("res://audio/player/stepdirt4.wav")
]

var sounds := {
	Surface.Rock : {
		Impact.Footstep: low_rock_sounds,
		Impact.ImpactLight: low_rock_sounds
	}
}

func step_on(surface: Node, position:Vector3, sliding := false, normal := Vector3.UP):
	var impact = Impact.Footstep if !sliding else Impact.SlidingStep
	impact_on(surface, impact, position, normal)

func impact_on(surface:Node, impact: int, position: Vector3, normal := Vector3.UP):
	if !surface:
		return
	var surf = Surface.Rock
	if surface.is_in_group("metal") || surface.is_in_group("enemy"):
		surf = Surface.Metal
	elif surface.is_in_group("glass"):
		surf = Surface.Glass
	elif surface.is_in_group("wood"):
		surf = Surface.Wood
	elif surface.is_in_group("grass"):
		surf = Surface.Grass
	elif surface.is_in_group("flag_surface"):
		surf = Surface.Sand
	impact(surf, impact, position, normal)


func impact(surf, impact, position: Vector3, normal := Vector3.UP):
	if surf in emitters and impact in emitters[surf]:
		var emitter_orig = emitters[surf][impact]
		var e: Particles
		var ename = _emitter_name(surf, impact)
		if ObjectPool.has(ename):
			e = ObjectPool.get(ename)
		else:
			e = emitter_orig.duplicate()
		emit_particles_once(e, position, normal)
	if surf in sounds and impact in sounds[surf] and impact in audio_players:
		var array:Array = sounds[surf][impact]
		var sound_orig = audio_players[impact]
		var s: AudioStreamPlayer3D
		var aname = _audio_player_name(impact)
		if ObjectPool.has(aname):
			s = ObjectPool.get(aname)
		else:
			s = sound_orig.duplicate()
		s.stream = array[randi() % array.size()]
		s.pitch_scale = rand_range(0.9, 1.2)
		play_sound_once(aname, s, position)

func emit_particles_once(e: Particles, position: Vector3, normal: Vector3):
	get_tree().current_scene.add_child(e)
	e.global_transform.origin = position
	var up = e.global_transform.basis.y
	var angle = up.angle_to(normal)
	if angle > 0.01:
		var axis = up.cross(normal).normalized()
		if axis.is_normalized():
			e.global_rotate(axis, angle)
	e.show()
	e.emitting = true
	yield(get_tree().create_timer(e.lifetime), "timeout")
	e.emitting = false
	e.get_parent().remove_child(e)
	ObjectPool.put(e.name, e)

func play_sound_once(type, s: AudioStreamPlayer3D, position: Vector3):
	get_tree().current_scene.add_child(s)
	s.global_transform.origin = position
	s.stop()
	s.play()
	yield(get_tree().create_timer(s.stream.get_length()), "timeout")
	s.stop()
	s.get_parent().remove_child(s)
	ObjectPool.put(type, s)

func _emitter_name(surface, impact):
	return "BE-" + str(surface) + "-" + str(impact)

func _audio_player_name(impact):
	return "BA-" + str(impact)
