@icon("./CampionatorePistone.gd.png")
extends ComponenteAudio
class_name CampionatorePistone

@export_category("CampionatorePistone")
#@export var motore : FisicaMotore
#@export var cilindro : int

@export var valve : Valve

@export_group("Dettagli campionamento")
@export_subgroup("Pressione")
@export_range(0.001,1.0) var moltiplicatore_pressione : float = 1.0
@export_range(1.0,3.0) var esponenzialita_pressione : float = 1.0
@export_range(0.0,1.0) var rumorosita_pressione : float = 0.0
@export_subgroup("Temperatura")
@export_range(0.0,1.0) var moltiplicatore_temperatura : float = 0.0
@export_range(1.0,3.0) var esponenzialita_temperatura : float = 1.0
@export_range(0.0,1.0) var rumorosita_temperatura : float = 0.0

@export_group("Buffer")
@export var lunghezza_buffer : int = 11025
# Quanto il puntatore scrittura del buffer partirà in avanti relativamnete alla
# lunghezza totale del buffer. Serve per evitare aggiornamenti di valori del
# buffer che stanno per esser letti.
@export_range(0.0, 1.0) var correction_delta_amount : float = 0.1

var samples_buffer : AudioSynchronizerBuffer = null
var reverb_buffer : AudioSynchronizerBuffer = null

func _enter_tree():
	samples_buffer = AudioSynchronizerBuffer.new(lunghezza_buffer)
	reverb_buffer = AudioSynchronizerBuffer.new(lunghezza_buffer)


func _physics_process(delta):
	samples_buffer.process_correction(correction_delta_amount)
	reverb_buffer.process_correction(correction_delta_amount)


func sample_audio() -> float:
	return samples_buffer.sample(0.0)


func sample_reverb() -> float:
	return reverb_buffer.sample(100.0)


func invia_campione(val_p: float, val_t : float, fase_albero : float):
	val_p *= moltiplicatore_pressione * 0.000001
	val_p = pow(val_p,esponenzialita_pressione)
	val_p = lerp(val_p, val_p * (randf()*2-1), rumorosita_pressione)
	
	val_t *= moltiplicatore_temperatura * 0.01
	val_t = pow(val_t,esponenzialita_temperatura)
	val_t = lerp(val_t, val_t * (randf()*2-1), rumorosita_temperatura)
	
	if valve != null :
		valve.set_valve_position(fase_albero)
		valve.set_pressure(val_p)
	
	samples_buffer.send_value(val_p + val_t)



func imposta_riverbero(volume : float, temperatura : float):
	var vel_suono : float = sqrt(391*temperatura)
	
	reverb_buffer.send_value(max(0.1, volume*44100000 / vel_suono))
