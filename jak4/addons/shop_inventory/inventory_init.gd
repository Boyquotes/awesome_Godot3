tool
extends EditorPlugin

var importer := ShopInventoryImportPlugin.new()

func _enter_tree():
	add_custom_type(
		"ShopInventory",
		"Resource",
		preload("res://addons/shop_inventory/inventory.gd"),
		preload("res://addons/shop_inventory/inventory_icon.png"))
	add_import_plugin(importer)

func _exit_tree():
	remove_import_plugin(importer)
	importer = null
	remove_custom_type("ShopInventory")
