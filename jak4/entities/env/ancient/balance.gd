extends Spatial

export(float) var angle = 25.0 setget set_angle

func set_angle(a):
	angle = a
	$"fulcrum/balance-kine".max_rotation_degrees = angle
