extends Resource
class_name Coat

enum Rarity {
	Common,
	Uncommon,
	Rare,
	SuperRare,
	Sublime
}

export(int) var rarity = Rarity.Common
export(Texture) var palette: Texture
export(Gradient) var gradient: Gradient

const max_int := 9223372036854775807
const MAX_COMMON := 0
const MAX_UNCOMMON:int = max_int/2
const MAX_RARE:int = int(max_int*0.8)
const MAX_SUPER_RARE:int = int(max_int*0.95)

static func rand64_range(min_rarity: int, max_rarity: int) -> int:
	var high: int
	var low: int
	match max_rarity:
		Rarity.Common:
			high = MAX_COMMON
		Rarity.Uncommon:
			high = MAX_UNCOMMON
		Rarity.Rare:
			high = MAX_RARE
		Rarity.SuperRare:
			high = MAX_SUPER_RARE
		Rarity.Sublime:
			high = max_int
	match min_rarity:
		Rarity.Common:
			low = -max_int
		Rarity.Uncommon:
			low = MAX_COMMON
		Rarity.Rare:
			low = MAX_UNCOMMON
		Rarity.SuperRare:
			low = MAX_RARE
		Rarity.Sublime:
			low = MAX_SUPER_RARE
	if min_rarity == Rarity.Common:
		var k = (randi()<<32) + randi()
		if k < 0:
			k = -k
		return high - k
	var g: int = ((randi()<<32) + randi()) % (high-low)
	if g < 0:
		g = -g
	return low + g
	
func _init(random := false,  min_rarity = Rarity.Common, max_rarity = Rarity.Uncommon):
	resource_name = "Coat"
	if !random:
		return
	
	if min_rarity > max_rarity:
		var t = min_rarity
		min_rarity = max_rarity
		max_rarity = t
	var cgen_seed := rand64_range(min_rarity, max_rarity)
		
	if Global.coat_textures.size() == 0:
		print_debug("No coat textures!")
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = cgen_seed
	
	var colors: int
	
	if cgen_seed < MAX_COMMON:
		rarity = Rarity.Common
	elif cgen_seed < MAX_UNCOMMON:
		rarity = Rarity.Uncommon
	elif cgen_seed < MAX_RARE:
		rarity = Rarity.Rare
	elif cgen_seed < MAX_SUPER_RARE:
		rarity = Rarity.SuperRare
	else:
		rarity = Rarity.Sublime
	
	if rarity < min_rarity:
		print("BUG: Seed was too low: ", cgen_seed)
		rarity = min_rarity
	elif rarity > max_rarity:
		print("BUG: Seed was too high: ", cgen_seed)
		rarity = max_rarity
	
	match rarity:
		Rarity.Common:
			colors = 2
		Rarity.Uncommon:
			colors = 3
		Rarity.Rare:
			colors = 4
		Rarity.SuperRare:
			colors = 5
		Rarity.Sublime:
			colors = 7
	
	gradient = Gradient.new()
	
	for p in range(colors):
		var o := rng.randf()
		var c := Color.from_hsv(rng.randf(), rng.randf(), rng.randf())
		if p <= 1:
			gradient.colors[p] = c
			gradient.offsets[p] = o
		else:
			gradient.add_point(o, c)
	
	palette = Global.coat_textures[cgen_seed % Global.coat_textures.size()]

func generate_material(backface_culling := true) -> Material:
	var mat = ShaderMaterial.new()
	if !backface_culling:
		mat.shader = load("res://material/coat_doublesided.shader")
	else:
		mat.shader = load("res://material/coat.shader")
	
	var gt := GradientTexture.new()
	gt.gradient = gradient
	gt.width = 64
	mat.set_shader_param("gradient", gt)
	mat.set_shader_param("softness", 0.25)
	mat.set_shader_param("palette", palette)
	mat.set_shader_param("detail", Global.get_coat_detail())
	
	return mat
