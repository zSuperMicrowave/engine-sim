extends Node3D
class_name Transmission

@export_range(0.01,100.0) var base_ratio := 1.0
@export var engine : ComponenteMotore
@export var gear_audios : Array[AudioStreamPlayer3D]
@export var disable_audio := false
@export var gearratios : Array[GearRatio]
@export var reverse_gears : Array[Array]
@export var forward_gears : Array[Array]
@onready var machinina : Machinina = get_parent()
var current_gear := 0
var clutch := 0.0

func _ready():
	for g in gear_audios:
		g.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
var cambiata := false
func _physics_process(delta):
	if Input.get_action_strength("marcia_su") > 0.96 :
		if not cambiata :
			if current_gear < 0 or current_gear < forward_gears.size():
				current_gear+=1
				cambiata = true
	elif Input.get_action_strength("marcia_giu") > 0.96 :
		if not cambiata:
			if current_gear > 0 or -current_gear < reverse_gears.size():
				current_gear-=1
				cambiata = true
	elif Input.get_action_strength("marcia_su") < 0.3 and Input.get_action_strength("marcia_giu") < 0.3:
		cambiata = false
	
	#print(current_gear)
	clutch = 1- Vector2(Input.get_action_strength("frizione"),
		max(Input.get_action_strength("marcia_giu"),
			Input.get_action_strength("marcia_su"))).distance_to(Vector2.ZERO)
	if current_gear == 0 :
		clutch = 0.0

func get_current_ratio() -> float:
	var current_gearratio := 1.0
	for i in range(gearratios.size()) :
		gearratios[i].enabled = false
		gear_audios[i*2].volume_db = -80.0
		gear_audios[i*2+1].volume_db = -80.0
	
	if current_gear > 0:
		for i in range(gearratios.size()):
			if forward_gears[current_gear-1][i] :
				current_gearratio *= gearratios[i].get_ratio()
				gearratios[i].enabled = true
				
				if engine.albero_motore.clutch > 0.9 :
					gear_audios[i*2].pitch_scale = get_gear_pitch_a(current_gearratio,i,0.1,5)
					gear_audios[i*2+1].pitch_scale = get_gear_pitch_b(current_gearratio,i,0.1,5)
				if not disable_audio:
					var vol = -30 + 15 * (Input.get_action_strength("pene_temp") / (0.5 + 50 * abs(machinina.get_avg_acc())))
					gear_audios[i*2].volume_db = vol
					gear_audios[i*2+1].volume_db = vol
	elif current_gear < 0:
		for i in range(gearratios.size()):
			if reverse_gears[-current_gear-1][i] :
				current_gearratio *= gearratios[i].get_ratio()
				gearratios[i].enabled = true
				
				if engine.albero_motore.clutch > 0.9 :
					gear_audios[i*2].pitch_scale = get_gear_pitch_a(current_gearratio,i,0.1,5)
					gear_audios[i*2+1].pitch_scale = get_gear_pitch_b(current_gearratio,i,0.1,5)
				if not disable_audio:
					var vol = -30 + 15 * (Input.get_action_strength("pene_temp") / (0.5 + 50 * abs(machinina.get_avg_acc())))
					gear_audios[i*2].volume_db = vol
					gear_audios[i*2+1].volume_db = vol
		current_gearratio *= -1
	
	return current_gearratio

func get_gear_pitch_a(current_ratio : float, gear : int, min: float, max : float):
	return clampf(engine.albero_motore.velocita_angolare * Unita.rpm / current_ratio\
		* gearratios[gear].teeth_multiplier * gearratios[gear].over_d\
		/ 2000, min, max)

func get_gear_pitch_b(current_ratio : float, gear : int, min: float, max : float):
	return clampf(engine.albero_motore.velocita_angolare * Unita.rpm / current_ratio\
		* gearratios[gear].teeth_multiplier * gearratios[gear].n\
		/ 2000, min, max)


func get_force():
	var ratio = get_current_ratio()
	return engine.get_force(machinina.get_wheel_rpm() * 0.3 * ratio * base_ratio ) * 0.05 * ratio * base_ratio

func get_inertia():
	var ratio = get_current_ratio()
	return engine.get_inertia(clutch * machinina.get_slip()) / (ratio * base_ratio+1.0)
