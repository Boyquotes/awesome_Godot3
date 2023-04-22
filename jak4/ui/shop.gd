extends Control

var keeper: Node
onready var items_window := $items

const proper_name: Dictionary = {
	"gem": "Gems",
	"bug": "Deathgnats"
}

var stock: Dictionary
const default_tooltips := {
	"health_up" : "Permanently increase health by 25%.",
	"stamina_up": "Pernanently increase stamina by 25%.",
	"stamina_recovery_up" : "Permanently increase stamina recovery speed by 20%.",
	"damage_up" : "Permanently increase melee damage by 15%.",
	"bug" : "One deathgnat",
	"flag": "A consumable checkpoint. You will respawn where the flag is placed until you reach a new checkpoint.",
	"armor": "Temporarily increase health by 24%. Consumed before health.",
	"stamina_booster": "Temporarily increase maximum stamina. Consumed after normal stamina."
}

func _init():
	stock = {}

func _ready():
	set_process_input(false)

func start_shopping(source: Node):
	if !source.has_method("get_inventory"):
		print_debug("Shop owner doesn't have an inventory!")
		return
	keeper = source
	stock.clear()
	draw_shop_window()
	
	if "visual_name" in source:
		$Label.text = source.visual_name
		$Label.show()
	else:
		$Label.hide()
	show()

func draw_shop_window():
	for c in items_window.get_children():
		c.queue_free()
	var inventory: ShopInventory = keeper.get_inventory()
	
	populate_window(inventory.persistent, true)
	populate_window(inventory.temporary, false)

func populate_window(items: Array, persistent: bool):
	var default_currency := "bug" if persistent else "gem"
	for item in items:
		#Terrible lol
		var currency := default_currency
		if item["I"] == "bug":
			currency = "gem"
			
		var item_tooltip = ""
		if "TT" in item:
			item_tooltip = item["TT"]
		elif item["I"] in default_tooltips:
			item_tooltip = default_tooltips[item["I"]]

		var amount = item["C"]
		var label = Label.new()
		var amount_label = Label.new()
		label.text = item["I"].capitalize()
		amount_label.text = str(amount) + " Left"

		var buy_button := Button.new()
		buy_button.text = "Buy for %d %s" % [item["$$"], proper_name[currency]]
		var _x = buy_button.connect(
			"pressed",
			self, "_on_buy_pressed", [item["I"]])
		if item_tooltip != "":
			_x = buy_button.connect(
				"focus_entered", self, "_on_item_focused", [label.text, item_tooltip])
		
		items_window.add_child(label)
		items_window.add_child(amount_label)
		items_window.add_child(buy_button)
		
		
		stock[item["I"]] = {
			"cost":item["$$"],
			"amount":item["C"],
			"currency":currency,
			"buy_button":buy_button,
			"amount_label":amount_label,
			"persistent":persistent,
			"tooltip": item_tooltip
		}
	update_available()

func update_available():
	for item_id in stock.keys():
		var item: Dictionary = stock[item_id]
		item.amount_label.text = str(item.amount)
		if item.amount <= 0:
			item.buy_button.disabled = true
			item.buy_button.text = "Sold Out!"
		var wallet = Global.count(item.currency)
		if wallet < item.cost:
			item.buy_button.disabled = true

func _on_buy_pressed(item_id: String):
	if !item_id in stock:
		print_debug("BUG: Tried to buy non-existant item ", item_id)
	var item: Dictionary = stock[item_id]
	var cost : int = int(item.cost)
	var currency : String = item.currency
	var amount : int = int(item.amount)
	if amount < 0:
		print_debug("BUG: Tried to buy out-of-stock ", item_id)
	var player_wallet:int = Global.count(currency)
	if player_wallet < cost:
		print_debug("BUG: Tried to buy unaffordable", item_id)
	item.amount -= 1
	var _x = Global.add_item(currency, -cost)
	_x = Global.add_item(item_id)
	keeper.mark_sold(item_id)
	update_available()

func _on_item_focused(item_name: String, item_tooltip: String):
	if item_tooltip != "":
		$tooltip.show()
		$tooltip.text = item_name + ": " + item_tooltip
	else:
		$tooltip.hide()
