extends Spatial

export(bool) var active := true setget set_active
export(float, 0.0, 3.0, 0.01) var move_scale := 1.0

onready var turbine := $generator/gen_motor
onready var propellers := $generator/gen_motor/gen_propellers

const TURN_MIN := 0.01
const TURN_MAX := 0.5
const SPIN_MIN := 0.01
const SPIN_MAX := 0.5

# Wind generation (same for all generators)
const WIND_PERIOD_1 := 2.0e5
const WIND_PERIOD_2 := 0.21

const WIND_PERIOD_3 := 3.1e6
const WIND_PERIOD_4 := 0.046

const WIND_AMPLITUDE_1 := 0.8
const WIND_AMPLITUDE_2 := 5.0

# Velocities
var turn := 0.0
var spin := 0.0

var time := 0.0

onready var accel_turn := rand_range(TURN_MIN, TURN_MAX)
onready var accel_spin := rand_range(SPIN_MIN, SPIN_MAX)

func set_active(a):
	active = a
	set_process(active)

func _process(delta):
	# Get random wind direction
	time += delta
	var v1 := WIND_AMPLITUDE_1*(0.01 + sin(0.578 + time*WIND_PERIOD_2))*Vector2(
		sin(time/WIND_PERIOD_1),
		-cos(time/WIND_PERIOD_1)
	)
	var v2 := WIND_AMPLITUDE_2*(0.02 + cos(.98 + time*WIND_PERIOD_4))*Vector2(
		sin(time/WIND_PERIOD_3),
		-cos(time/WIND_PERIOD_3)
	)
	
	var wind := v1 + v2
	
	# Apply wind
	var desired_dir := Vector3(-wind.x, 0, -wind.y)
	var lateral_force := desired_dir.dot(-turbine.global_transform.basis.x)
	var parallel_force := desired_dir.dot(propellers.global_transform.basis.z)
	
	turn += move_scale*delta*accel_turn*lateral_force
	turn *= clamp(1.0 - 4*delta, 0.0, 1.0)
	spin += delta*accel_spin*parallel_force
	
	turbine.rotate_y(0.2*delta*turn)
	propellers.rotate_z(move_scale*0.2*delta*spin)
