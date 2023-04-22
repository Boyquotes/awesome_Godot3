extends Spatial

export(bool) var generate_on_ready := false
export(bool) var regenerate_on_death := false
export(bool) var ignore_parent := false

var generated := false

func _ready():
	if generate_on_ready:
		if regenerate_on_death:
			var _x = Global.get_player().connect("died", self, "generate", [true])
		generate()
	elif !ignore_parent:
		var p = get_parent()
		if p is Door:
			p.connect("opened", self, "generate")

func generate(force := false):
	if generated and !force:
		return
	for c in get_children():
		c.queue_free()
	var a = AmmoSpawner.get_random_ammo()
	if a:
		add_child(a)
		a.global_transform = global_transform
		a.show()
		var _x = a.connect("picked", self, "_on_picked", [], CONNECT_ONESHOT)
	generated = true

func _on_picked():
	generated = false
