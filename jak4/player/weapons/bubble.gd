extends Area

signal remove(node)

export(Vector3) var direction := Vector3.ZERO
export(int) var damage := 10

onready var col = $CollisionShape
onready var mesh = $MeshInstance

func _ready():
	var _x = connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if !body.has_method("take_damage"):
		return
	var dir := direction
	if dir == Vector3.ZERO:
		dir = (body.global_transform.origin - global_transform.origin).normalized()
	body.take_damage(damage, dir, Global.get_player()) # TODO what if someone else fired it?

func fire(r, time_firing):
	$AnimationPlayer.stop()
	$AnimationPlayer.play("fire")
	$Tween.interpolate_property(mesh, "scale", 
		Vector3(0.1, 0.1, 0.1), Vector3(r,r,r), time_firing,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_property(col.shape, "radius",
		0.1, r, time_firing,
		Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()

func make_unique():
	col.shape = col.shape.duplicate()
	mesh.set_surface_material(0, mesh.get_surface_material(0).duplicate())

func _on_animation_finished(_a):
	emit_signal("remove", self)
