extends Node

# Ammo drop logic
const ammo_path_f := "res://items/ammo/%s_pickup.tscn"
const WEIGHTS := {
	"pistol": 1.12,
	"wave_shot": 1.07,
	"grav_gun": 1.0
}

var MAX := {
	"pistol": 20.0,
	"wave_shot":14.0,
	"grav_gun": 9.0
}
var MAX2 := {
	"pistol":50.0,
	"wave_shot":28.0,
	"grav_gun":18.0
}
var MAX3 := {
	"pistol":100.0,
	"wave_shot":42.0,
	"grav_gun":27.0
}

const COUNTS := {
	"pistol": 5,
	"wave_shot":3,
	"grav_gun": 2
}

func max_ammo(weapon_type):
	if !weapon_type in MAX:
		return -1
	var upgrades = Global.count(weapon_type + "_capacity_up")
	if upgrades >= 2:
		return MAX3[weapon_type]
	elif upgrades >= 1:
		return MAX2[weapon_type]
	else:
		return MAX[weapon_type]

func get_random_ammo():
	var best_wep := ""
	var best_desire := -INF
	for a in WEIGHTS.keys():
		var m = max_ammo(a)
		if Global.count("wep_"+a):
			var n:float = (m - Global.count(a))/m
			var desire = WEIGHTS[a]*(n + randf()*0.5)
			if desire >= best_desire:
				best_wep = a
				best_desire = desire
	if best_wep != "":
		var tscn = load(ammo_path_f % best_wep) as PackedScene
		var ammo = tscn.instance() as ItemPickup
		ammo.quantity = COUNTS[best_wep]
		return ammo
	else:
		return null
