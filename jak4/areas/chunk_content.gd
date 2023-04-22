tool
extends Spatial
class_name Chunk

export(NodePath) var grass_node := NodePath("active_entities/grass")
export(float) var grass_density := 1.0
var exits: Array

var active_entities : Spatial
var active_transform : Transform

func _init():
	exits = []

func _ready():
	if Engine.editor_hint:
		var world :PackedScene= load("res://areas/world_reference.tscn")
		var world_node = world.instance()
		if world_node.has_node(name):
			print_debug("Previewing ", name)
			var m = world_node.get_node(name)
			m.get_parent().remove_child(m)
			add_child(m)
			m.name = "__autogen_preview"
			m.transform = Transform()
		else:
			print_debug("No chunk of name ", name)
		world_node.free()

func find_exit_to(place: String):
	for e in exits:
		if e.destinations.contains(place):
			return e

func set_active(a):
	if !a and has_node("active_entities"):
		active_entities = $active_entities
		active_transform = active_entities.transform
		remove_child(active_entities)
	elif a and active_entities and !has_node("active_entities"):
		add_child(active_entities)
		active_entities.transform = active_transform
