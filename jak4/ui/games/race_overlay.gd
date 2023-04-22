extends Control

export(float) var gold setget set_gold
export(float) var silver setget set_silver
export(float) var bronze setget set_bronze

func set_best(best: float):
	$Panel/MarginContainer/GridContainer/LabelBest.show()
	$Panel/MarginContainer/GridContainer/Best.show()
	$Panel/MarginContainer/GridContainer/Best.text = "%.3f" % best

func new_best(best:float):
	$Panel/MarginContainer/GridContainer/LabelBest.show()
	$Panel/MarginContainer/GridContainer/Best.show()
	$Panel/MarginContainer/GridContainer/Best.text = "%.3f" % best
	$best.text = "New best: %.3f" % best
	$AnimationPlayer.play("new_best")

func set_gold(g: float):
	$Panel/MarginContainer/GridContainer/Gold.text = "%.2f" % g
	gold = g

func set_silver(s: float):
	$Panel/MarginContainer/GridContainer/Silver.text = "%.2f" % s
	silver = s
	
func set_bronze(b: float):
	$Panel/MarginContainer/GridContainer/Bronze.text = "%.2f" % b
	bronze = b

func color_bronze(c: Color):
	$Panel/MarginContainer/GridContainer/LabelBronze.modulate = c
	$Panel/MarginContainer/GridContainer/Bronze.modulate = c

func color_silver(c: Color):
	$Panel/MarginContainer/GridContainer/LabelSilver.modulate = c
	$Panel/MarginContainer/GridContainer/Silver.modulate = c

func color_gold(c: Color):
	$Panel/MarginContainer/GridContainer/LabelGold.modulate = c
	$Panel/MarginContainer/GridContainer/Gold.modulate = c
