extends Spatial

var custom_coat_stat = ""

onready var hat: MeshInstance = $Armature/Skeleton/attach_hat/ref_hat/MeshInstance

func _ready():
	var p = get_parent()
	if p and ("friendly_id" in p) and (p.friendly_id != ""):
		custom_coat_stat = "coats/" + p.friendly_id
	if p and "accessory" in p and p.accessory:
		hat.mesh = p.accessory
	var coat = Global.stat(coat_stat())
	if !coat:
		coat = generate_coat()
	show_coat(coat)

func generate_coat(min_rarity = Coat.Rarity.Uncommon, max_rarity = Coat.Rarity.Sublime):
	return Global.set_stat(coat_stat(), Coat.new(true, min_rarity, max_rarity))

func coat_stat() -> String:
	if custom_coat_stat == "":
		return "coats/" + Global.node_stat(get_parent())
	else:
		return custom_coat_stat

func show_coat(coat: Coat):
	var mat = coat.generate_material(false)
	$Armature/Skeleton/body.set_surface_material(1, mat)
	if hat.get_surface_material_count() > 0:
		hat.set_surface_material(0, mat)
