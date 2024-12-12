class_name PistonSamplerBufferManager extends Node

func _physics_process(delta):
	for c in get_children():
		if c is CampionatorePistone :
			c.samples_buffer.
