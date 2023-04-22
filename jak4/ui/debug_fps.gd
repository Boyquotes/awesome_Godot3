extends Label

var running_delta: float


func _process(delta):
	running_delta += delta*1000
	running_delta /= 2
	text = "[%.2f] : [%.2f]" % [delta*1000, running_delta]
