extends VehicleBody3D
class_name Machinina

@export var trans : Transmission
@export var base_mass := 100
func _ready():
	pass

var old_rpm := 0.0
var delta_rpm := 0.0
var avg_acc := 0.0
func _physics_process(delta):
	delta_rpm = (get_wheel_rpm() - old_rpm)*delta
	old_rpm = get_wheel_rpm()
	avg_acc = lerpf(avg_acc,delta_rpm,delta*2)
	var intertia_mass = 15*trans.get_inertia()
	mass = base_mass + intertia_mass
	engine_force = trans.get_force() * 15
	trans.engine.albero_motore.set_delta(delta)
	#print((Input.get_action_strength("freno1")+1-Input.get_action_strength("freno2"))*0.5)
	brake = 10 * (Input.get_action_strength("freno1")+1-Input.get_action_strength("freno2"))*0.5
	
	steering = (-Input.get_action_strength("sterzo_pos") + Input.get_action_strength("sterzo_neg"))*0.6

func get_avg_acc():
	return avg_acc



func get_slip():
	var a = $rr.get_skidinfo()
	var b = $rl.get_skidinfo()
	if not $rr.is_in_contact() :
		a = 0.0
	if not $rl.is_in_contact() :
		b = 0.0
	return (a + b)*0.5

func get_wheel_rpm():
	return max(($rr.get_rpm() + $rl.get_rpm())*0.5,0.0)
