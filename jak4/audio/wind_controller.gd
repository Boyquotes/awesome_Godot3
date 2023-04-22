extends AudioStreamPlayer
class_name WindController

# player positions
const CEILING := 4000.0
const FLOOR := -50.0

const MAX_DB_FLOOR := -10.0
const MIN_DB_FLOOR := -40.0 
const MAX_DB_CEIL := 20.0
const MIN_DB_CEIL := 0.0

const MAX_FREQ_FLOOR := 1.1
const MIN_FREQ_FLOOR := 0.65
const MAX_FREQ_CEIL := 2.0
const MIN_FREQ_CEIL := 0.8

const SPEED_INTERP := 0.4
var interp := 0.0

var speed_volume := 20.0
var ve := 1.0
var t_volume := 1.0

var noise := OpenSimplexNoise.new()

var noise_sample := 0.0

func _ready():
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8

func _process(delta):
	var pos:Vector3 = Global.get_player().global_transform.origin
	var new_interp := sqrt(clamp((pos.y - FLOOR)/(CEILING - FLOOR), 0, 1))
	if new_interp < interp:
		interp = max(new_interp, interp-delta*SPEED_INTERP)
	elif new_interp > interp:
		interp = min(new_interp, interp+delta*SPEED_INTERP)
		
	if t_volume < ve:
		ve = max(t_volume, ve - speed_volume*delta)
	elif t_volume > ve:
		ve = min(t_volume, ve + speed_volume*delta)
	
	var max_vol:float = lerp(MAX_DB_FLOOR, MAX_DB_CEIL, interp)
	var min_vol:float = lerp(MIN_DB_FLOOR, MIN_DB_CEIL, interp)
	var max_pitch:float = lerp(MAX_FREQ_FLOOR, MAX_FREQ_CEIL, interp)
	var min_pitch:float = lerp(MIN_FREQ_FLOOR, MIN_FREQ_CEIL, interp)
	
	noise_sample += delta
	var n := 0.5 + 0.5*noise.get_noise_1d(noise_sample)
	var vol:float = lerp(min_vol, max_vol, n)
	var freq:float = lerp(min_pitch, max_pitch, n)
	volume_db = vol + ve
	pitch_scale = freq
	$"../debug/box/Label7".text = str(pitch_scale)

# Smoothly change volume
# Negative to reduce volume
# Positive to increase it (not recommended)
func apply_volume(volume: float):
	speed_volume = max(abs(volume), abs(t_volume))/2.0
	t_volume = volume
