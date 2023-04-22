extends AudioStreamPlayer

export(AudioStream) var default_explore_music
export(AudioStream) var default_combat_music

onready var combat := $combat

var TENSION_FADE_IN := 30.0
var TENSION_FADE_OUT := 8.0
var MIN_DB := -80.0
var FADEOUT_SPEED := 20.0
var FADEIN_SPEED := 40.0

var in_combat := false
var fadeout := false

var next_up_explore : AudioStream
var next_up_combat : AudioStream

func _ready():
	reset()

func _process(delta):
	if fadeout:
		var change = FADEOUT_SPEED*delta
		volume_db -= change
		combat.volume_db -= change
		if volume_db <= MIN_DB and combat.volume_db <= MIN_DB:
			volume_db = MIN_DB
			combat.volume_db = MIN_DB
			play_next()
		return
	if !stream and !combat.stream:
		return
	elif !combat.stream:
		# just fade in the exploration track
		if combat.playing:
			combat.playing = false
		if !playing:
			play()
		if volume_db < 0.0:
			volume_db += FADEIN_SPEED*delta
			if volume_db > 0:
				volume_db = 0
	elif !stream:
		if !combat.playing:
			combat.play()
		if playing:
			playing = false
		# just combat music
		if in_combat:
			if combat.volume_db < 0:
				combat.volume_db += TENSION_FADE_IN*delta
		else:
			if combat.volume_db > MIN_DB:
				combat.volume_db -= TENSION_FADE_OUT*delta
		combat.volume_db = clamp(combat.volume_db, MIN_DB, 0.0)
	else:
		#TODO: synchronize combat and exploration music, if I want that
		# just fade in the exploration track for now
		if combat.playing:
			combat.playing = false
		if !playing:
			play()
		if volume_db < 0.0:
			volume_db += FADEIN_SPEED*delta
			if volume_db > 0:
				volume_db = 0
			

func set_music(default_override, combat_override):
	fadeout = true
	next_up_explore = default_override
	next_up_combat = combat_override

func play_next():
	stream = next_up_explore
	combat.stream = next_up_combat
	play()
	combat.playing = false
	fadeout = false

func reset():
	set_music(default_explore_music, default_combat_music)

func play_music(music: AudioStream):
	set_music(music, null)

func stop_music():
	reset()
