extends TextureRect
class_name Speedometer

var rpm = 0.0

func _process(delta):
	get_child(0).rotation = PI * rpm/20_000 - PI/2
