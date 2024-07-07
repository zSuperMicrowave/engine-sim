extends VehicleBody3D
class_name Machinina

@export var trans : Transmission
@export var base_mass := 100
func _ready():
	pass


func _physics_process(delta):
	mass = base_mass + trans.get_inertia()*1
	engine_force = trans.get_force() * 7
	trans.engine.albero_motore.set_delta(delta)
	print(trans.current_gear)
	
	steering = -Input.get_action_strength("sterzo_pos") + Input.get_action_strength("sterzo_neg")


func get_slip():
	return ($rr.get_skidinfo() + $rl.get_skidinfo())*0.5

func get_wheel_rpm():
	return max(($rr.get_rpm() + $rl.get_rpm())*0.5,0.0)
