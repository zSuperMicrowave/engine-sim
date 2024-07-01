extends Node3D

@export var traccia : Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position = global_position.lerp(traccia.global_position,delta*10.0)
	global_transform.basis.from_euler(global_transform.basis.get_rotation_quaternion().slerp(traccia.global_transform.basis.get_rotation_quaternion(),delta*10.0).get_euler())
