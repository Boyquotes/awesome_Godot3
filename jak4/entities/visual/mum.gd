tool
extends Spatial

export(Material) var hologram_material
export(Material) var hidden_material

export(bool) var real_visible := false setget set_real_visible

func hello():
	$AnimationPlayer.play("IntroWalk")
	if Global.stat("mum/appearance"):
		$vis_anim.play("Show")
	else:
		$vis_anim.play("Show_Partial")

func bye():
	if Global.stat("mum/appearance"):
		$vis_anim.play("Hide")
	else:
		$vis_anim.play("Hide_Partial")

func set_real_visible(v):
	real_visible = v
	if is_inside_tree():
		var mat = null if v else hidden_material
		$Armature/Skeleton/mum.material_override = mat
		$Armature/Skeleton/mum_deatail.material_override = mat
