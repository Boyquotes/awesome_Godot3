extends Node

var captain_redford : FollowerNPC

func _ready():
	var _x = Global.connect("stat_changed", self, "_on_stat_changed")
	if Global.stat("manor052/investigation1"):
		_on_stat_changed("investigation1", 1)

func _on_front_door_opened():
	var _x = Global.add_stat("chunk052/front_door/open")

func _on_stat_changed(stat_name, value):
	if !value:
		return
	match stat_name:
		"manor052/investigation1":
			$"../active_entities/zone_estate/rotating_map_dialog".enabled = true

func _on_rotating_map_completed():
	$"../active_entities/zone_estate/bookshelf".add_power()
	$"../active_entities/zone_estate/rotating_map_dialog".enabled = false
