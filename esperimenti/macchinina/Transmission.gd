extends Node3D
class_name Transmission

@export_range(0.01,100.0) var base_ratio := 1.0
@export var engine : ComponenteMotore
@export var gearratio : Array[GearRatio]
@export var reverse_gears : Array[Array]
@export var forward_gears : Array[Array]
@onready var machinina : Machinina = get_parent()
var current_gear := 0
var clutch := 0.0

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var cambiata := false
func _physics_process(delta):
	if Input.get_action_strength("marcia_su") > 0.5 :
		if not cambiata :
			if current_gear < 0 or current_gear < forward_gears.size()-1:
				current_gear+=1
				cambiata = true
	elif Input.get_action_strength("marcia_giu") > 0.5 :
		if not cambiata:
			if current_gear > 0 or -current_gear < reverse_gears.size()-1:
				current_gear-=1
				cambiata = true
	else :
		cambiata = false
	
	#print(current_gear)
	clutch = 1-max(Input.get_action_strength("frizione"),
		Input.get_action_strength("marcia_giu"),
		Input.get_action_strength("marcia_su"))
	if current_gear == 0 :
		clutch = 0.0

func get_current_ratio() -> float:
	var current_gearratio := 1.0
	for g in gearratio :
		g.enabled = false
	
	if current_gear > 0:
		for i in forward_gears[current_gear-1]:
			current_gearratio *= gearratio[i].get_ratio()
			gearratio[i].enabled = true
	elif current_gear < 0:
		for i in forward_gears[-current_gear-1]:
			current_gearratio *= gearratio[i].get_ratio()
			gearratio[i].enabled = true
		current_gearratio *= -1
	
	return current_gearratio

func get_force():
	var ratio = get_current_ratio()
	return engine.get_force(machinina.get_wheel_rpm() * base_ratio * ratio) * ratio * base_ratio

func get_inertia():
	var ratio = get_current_ratio()
	return engine.get_inertia(clutch) * ratio * base_ratio
