extends Area

signal disappeared(node)

export(int) var damage := 10
var damaged_nodes : Array

func make_unique():
	$CollisionShape.shape = $CollisionShape.shape.duplicate()
	$MeshInstance.set_surface_material(0, $MeshInstance.get_surface_material(0).duplicate())

func _ready():
	if !is_connected("body_entered", self, "_on_body_entered"):
		var _x = connect("body_entered", self, "_on_body_entered")
	damaged_nodes = []
	$AnimationPlayer.stop()
	$AnimationPlayer.play("fire")

func _on_body_entered(body):
	if !body.has_method("gravity_stun"):
		if body is RigidBody:
			Global.gravity_stun_body(body)
		return
	if body in damaged_nodes:
		return
	damaged_nodes.append(body)
	body.gravity_stun(damage)

func _on_animation_finished(_a):
	emit_signal("disappeared", self)
