extends Spatial
class_name GameRace

enum Award {
	Bronze = 1,
	Silver = 2,
	Gold = 3
}

export(float) var bronze_seconds: float
export(float) var silver_seconds: float
export(float) var gold_seconds: float
export(int) var bronze_reward := 3
export(int) var silver_reward := 5
export(int) var gold_reward := 10
export(bool) var gold_gives_coat := true
export(Coat.Rarity) var min_rarity := Coat.Rarity.Uncommon
export(Coat.Rarity) var max_rarity := Coat.Rarity.Rare
export(bool) var cross_chunk := false
export(String) var friendly_id := ""
export(bool) var hover_scooter := false
export(Array, String) var required_items: Array
export(Array, NodePath) var checkpoints: Array

const DANGER_TIME := 10.0
const DANGER_COLOR := Color.gold
const EXPIRED_COLOR := Color.salmon
const WON_COLOR := Color.aquamarine

onready var race_start: Spatial = $race_start
onready var race_end: Area = $race_end
onready var timer: Timer

var remaining_points : Array
var next_point : Area

const race_overlay: PackedScene = preload("res://ui/games/race_overlay.tscn")
const coat_scene : PackedScene = preload("res://items/coat_pickup.tscn")

var active := false
var player: PlayerBody
var overlay : Node

var at_end := false

var title := "Time"
onready var id := hash(get_path())

func _ready():
	if hover_scooter and !"hover_scooter" in required_items:
		required_items.append("hover_scooter")
	if has_node("Timer"):
		timer = $Timer
	else:
		timer = Timer.new()
		add_child(timer)
	timer.time_scale_response = false
	timer.one_shot = true
	var _x = timer.connect("timeout", self, "_fail")
	set_process(false)

func _process(_delta):
	var running_time := bronze_seconds - timer.time_left
	player.game_ui.value = "%.2f" % running_time
	
	if running_time > gold_seconds:
		overlay.color_gold(EXPIRED_COLOR)
	elif running_time + DANGER_TIME > gold_seconds:
		overlay.color_gold(DANGER_COLOR)
	
	if running_time > silver_seconds:
		overlay.color_silver(EXPIRED_COLOR)
	elif running_time + DANGER_TIME > silver_seconds:
		overlay.color_silver(DANGER_COLOR)
	
	if running_time + DANGER_TIME > bronze_seconds:
		overlay.color_bronze(DANGER_COLOR)
	
	if active and at_end and (
		(player.is_grounded() or player.is_hovering())
		and player in race_end.get_overlapping_bodies()
	):
		win()

func start_race():
	if CustomGames.is_active():
		return
	
	at_end = false
	CustomGames.start(self)
	CustomGames.set_spawn(race_start.global_transform)
	player = Global.get_player()
	
	player.can_use_hover_scooter = hover_scooter
	
	remaining_points = []
	if checkpoints:
		for point in checkpoints:
			if has_node(point):
				remaining_points.append(get_node(point))
	remaining_points.append(race_end)

	overlay = race_overlay.instance()
	overlay.gold = gold_seconds
	overlay.silver = silver_seconds
	overlay.bronze = bronze_seconds
	if CustomGames.has_stat(self, "best"):
		var best: float = CustomGames.stat(self, "best")
		overlay.set_best(best)
	connect_next_point(null)
	player.game_ui.set_overlay(overlay)
	
	active = true
	set_process(true)
	timer.start(bronze_seconds)

func connect_next_point(_body):
	if next_point:
		print("Passed ", next_point.name)
		player.game_ui.remove_target(next_point)

	if remaining_points.empty():
		at_end = true
	else:
		next_point = remaining_points.pop_front()
		player.game_ui.add_target(next_point)
		var _x = next_point.connect(
			"body_entered", self, "connect_next_point",
			[], CONNECT_ONESHOT | CONNECT_DEFERRED)

func _fail():
	if active:
		overlay.color_bronze(EXPIRED_COLOR)
		overlay.color_silver(EXPIRED_COLOR)
		overlay.color_gold(EXPIRED_COLOR)
		CustomGames.end(false)

func end():
	if next_point and next_point.is_connected("body_entered", self, "connect_next_point"):
		next_point.disconnect("body_entered", self, "connect_next_point")
	player.can_use_hover_scooter = true
	active = false
	set_process(false)
	overlay = null
	timer.stop()

func win():
	var last_award: int = CustomGames.stat(self, "award")
	var best_time: float = CustomGames.stat(self, "best")
	var race_time = bronze_seconds - timer.time_left
	
	if best_time == 0 or race_time < best_time:
		CustomGames.set_stat(self, "best", race_time)
		overlay.new_best(race_time)

	player.celebrate()
	
	var award: int
	if race_time <= gold_seconds:
		overlay.color_gold(WON_COLOR)
		award = Award.Gold
	elif race_time <= silver_seconds:
		overlay.color_silver(WON_COLOR)
		award = Award.Silver
	else:
		overlay.color_bronze(WON_COLOR)
		award = Award.Bronze
	
	CustomGames.end(true)
	
	if award <= last_award:
		return
	CustomGames.set_stat(self, "award", award)
	
	if award >= Award.Bronze and last_award < Award.Bronze:
		var _x = Global.add_item("bug", bronze_reward)
		_x = Global.add_item("bronze_medal")
	if award >= Award.Silver and last_award < Award.Silver:
		var _x = Global.add_item("bug", silver_reward)
		_x = Global.add_item("silver_medal")
	if award >= Award.Gold and last_award < Award.Gold:
		var _x = Global.add_item("bug", gold_reward)
		_x = Global.add_item("gold_medal")
		if gold_gives_coat:
			var c = coat_scene.instance()
			c.coat = Coat.new(true, min_rarity, max_rarity)
			c.gravity = true
			race_end.add_child(c)
			c.global_transform = race_end.global_transform

func has_required_items():
	if !required_items:
		return true
	for c in required_items:
		var stats = c.split("*")
		var count := 1
		if stats.size() > 1:
			count = int(stats[1])
		if !Global.count(stats[0]) >= count:
			return false
	return true
