extends PathFollow

export(bool) var active := true setget set_active
export(float) var cycles_per_second := 0.1

func _ready():
	if !is_in_group("dynamic"):
		add_to_group("dynamic")

func _physics_process(delta):
	unit_offset += cycles_per_second*delta

func set_active(a):
	active = a
	set_physics_process(active)
