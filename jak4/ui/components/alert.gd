extends Control

export(String) var format := ""

func show_alert(params):
	$Label.text = tr(format) % params
	$AnimationPlayer.play("show_and_fade")
