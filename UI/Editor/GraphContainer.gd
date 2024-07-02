extends Control


var focussed := false
var children_scale := 1.0
var zoom_position := Vector2.ZERO

var base_positions := {}



func _process(delta):
	var rect = get_global_rect()
	var mouse_position = get_global_mouse_position()
	if rect.has_point(mouse_position):
		# Mouse in rect
		if Input.is_action_just_pressed("scroll_up") :
			zoom_position -= (mouse_position - rect.position) * 1.1
			children_scale *= 1.1
		if Input.is_action_just_pressed("scroll_down") :
			zoom_position += (mouse_position - rect.position) / 1.1
			children_scale /= 1.1
	
	for c in get_children() :
		if not base_positions.has(c) :
			base_positions.merge({c : c.position})
		c.position = base_positions[c] * children_scale + zoom_position
		c.scale = Vector2.ONE * children_scale
