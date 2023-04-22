extends Object
class_name AudioSettings

export(Resource) var master_audio = AudioChannel.new("Master")
export(Resource) var music = AudioChannel.new("Music")
export(Resource) var sfx = AudioChannel.new("SFX")

func get_name() -> String:
	return "Audio"

func set_option(property, value):
	get(property).apply(value)
