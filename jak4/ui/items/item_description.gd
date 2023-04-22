extends Resource
class_name ItemDescription

enum Category {
	Firearm,
	Equipment,
	Sundries,
	Keys,
}

export(Category) var category
export(Texture) var custom_icon
export(PackedScene) var preview_3d
export(String) var full_name
export(String, MULTILINE) var description
# key: item id
# value: visual name
export(Dictionary) var extra_items
