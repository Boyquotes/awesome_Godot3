extends Control

signal pressed(framedata)

var framedata:FrameData

func set_framedata(p_fd):
	framedata = p_fd
	var runtime = framedata.frame_time
	
	$ColorRect.rect_min_size.y += clamp(0.01*runtime, 0, 400)
	if runtime > 30000:
		$ColorRect.color = Color.red
	elif runtime > 17000:
		$ColorRect.color = Color.orange
	elif runtime > 6094:
		$ColorRect.color = Color.lightgreen
	else:
		$ColorRect.color = Color.cadetblue

func _on_Button_pressed():
	emit_signal("pressed", framedata)
