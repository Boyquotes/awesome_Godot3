tool
extends EditorImportPlugin
class_name ShopInventoryImportPlugin

func get_importer_name():
	return "game.shop_inventory"

func get_visible_name():
	return "Shop Inventory"

func get_recognized_extensions():
	return ["inv"]

func get_save_extension():
	return "tres"

func get_resource_type():
	return "Resource"

func get_preset_count():
	return 1

func get_preset_name(_preset):
	return "Shop Inventory"

func get_import_options(preset):
	return []

func import(src_path: String, 
	dest_path: String,
	options: Dictionary, 
	r_platform_variants: Array, 
	r_gen_files: Array
):
	var in_file := File.new()
	var err := in_file.open(src_path, File.READ)
	if err != OK:
		print_debug("Inventory: failed to open %s, error code %d" 
			% [src_path, err])
		return err
	
	var text := in_file.get_as_text()
	in_file.close()
	
	var jpr := JSON.parse(text)
	if !jpr.error == OK:
		print_debug("Inventory: file %s was not valid json.\n[Line %d] %s"
			% [src_path, jpr.error_line, jpr.error_string])
		return jpr.error
	var json = jpr.result
	if !json:
		print_debug("Inventory: no JSON found for ", src_path)
	var inv := ShopInventory.new()
	if "persistent" in json:
		if !(json.persistent is Array):
			print_debug("Inventory: %s has bad persistent data (expected array)" % src_path)
			return ERR_INVALID_DATA
		for item in json.persistent:
			if !validate_entry(item):
				print_debug("Inventory: %s has a bad persistent item" % src_path)
				return ERR_INVALID_DATA
		inv.persistent = json.persistent

	if "temporary" in json:
		if !(json.temporary is Array):
			print_debug("Inventory: %s has bad temporary data (expected array)" % src_path)
			return ERR_INVALID_DATA
		for item in json.temporary:
			if !validate_entry(item):
				print_debug("Inventory: %s has a bad temporary item" % src_path)
				return ERR_INVALID_DATA
		inv.temporary = json.temporary
	ResourceSaver.save("%s.%s" % [dest_path, get_save_extension()], inv)
	return OK

func validate_entry(entry: Dictionary)->bool:
	if !("I" in entry):
		print_debug("Error: no item ID (I): ", entry)
		return false
	if !("C" in entry):
		print_debug("Error: no item quantity (C): ", entry)
		return false
	if !("$$" in entry):
		print_debug("Error: no item cost ($$): ",  entry)
		return false
	return true
