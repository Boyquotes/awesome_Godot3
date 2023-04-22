extends DirectionalLight

var distance := 1.0 setget set_distance
var high_quality := true setget set_quality

var d_split1 := directional_shadow_split_1
var d_split2 := directional_shadow_split_2
var d_distance := directional_shadow_max_distance

const orthogonal_shadow_distance = 30.0

func set_distance(d):
	distance = d
	directional_shadow_split_1 = lerp(0.1, d_split1, clamp(distance, 0, 1))
	directional_shadow_split_2 = lerp(0.4, d_split2, clamp(distance, 0, 1))
	apply_distance()

func set_quality(q):
	high_quality = q
	if high_quality:
		directional_shadow_mode = DirectionalLight.SHADOW_PARALLEL_4_SPLITS
	else:
		directional_shadow_mode = DirectionalLight.SHADOW_ORTHOGONAL
	apply_distance()

func apply_distance():
	directional_shadow_max_distance = (d_distance*distance if high_quality else orthogonal_shadow_distance)

func update_rotation():
	global_rotation = $"../sun_true_rotation".global_rotation
