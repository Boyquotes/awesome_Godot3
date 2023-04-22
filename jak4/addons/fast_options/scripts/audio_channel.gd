extends Resource
class_name AudioChannel

export(float) var vol: float
export(bool) var muted: bool
export(String) var bus_name: String

func _init(name: String = ""):
	resource_name = "AudioChannel"
	bus_name = name
	var bi = AudioServer.get_bus_index(bus_name)
	if bi >= 0:
		muted = AudioServer.is_bus_mute(bi)
		vol = db_to_percent(AudioServer.get_bus_volume_db(bi))

func apply(c):
	vol = c.vol
	muted = c.muted
	var bi = AudioServer.get_bus_index(bus_name)
	if bi >= 0:
		AudioServer.set_bus_mute(bi, muted)
		AudioServer.set_bus_volume_db(bi, percent_to_db(vol))

func percent_to_db(percent):
	if percent >= 1:
		return lerp(0, 6, percent - 1)
	else:
		return lerp(-60, 0, percent)

func db_to_percent(db):
	if db > 0:
		return db/6.0 + 1
	else:
		return (db + 60)/60
