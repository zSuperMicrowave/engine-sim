@icon("./CampionatorePistone.gd.png")
extends ComponenteAudio
class_name CampionatorePistone

@export_category("CampionatorePistone")
#@export var motore : FisicaMotore
#@export var cilindro : int

@export var valve : Valve
@export var use_valve := true

@export_group("Dettagli campionamento")
@export_subgroup("Pressione")
@export_range(0.001,1.0) var moltiplicatore_pressione : float = 1.0
@export_range(1.0,3.0) var esponenzialita_pressione : float = 1.0
@export_range(0.0,1.0) var rumorosita_pressione : float = 0.0
@export_subgroup("Temperatura")
@export_range(0.0,1.0) var moltiplicatore_temperatura : float = 0.0
@export_range(1.0,3.0) var esponenzialita_temperatura : float = 1.0
@export_range(0.0,1.0) var rumorosita_temperatura : float = 0.0

@export_group("Dettagli riverbero")
@export_range(0.0,1.0) var contributo_riverbero_pressione : float
var lunghezza_riverbero_attuale : float = 1000.0

@export_group("Buffer")
@export var lunghezza_buffer : int = 11025
# Quanto il puntatore scrittura del buffer partirà in avanti relativamnete alla
# lunghezza totale del buffer. Serve per evitare aggiornamenti di valori del
# buffer che stanno per esser letti.
@export_range(0.0, 1.0) var correction_delta_amount : float = 0.1

var buffer : RingBuffer = null

func _enter_tree():
	var arr := Array()
	for i in range(lunghezza_buffer * 0.5) :
		arr.push_back(0.0)
	
	buffer = RingBuffer.new(lunghezza_buffer,arr)


var avg_buffer_size := 0
var count_avg_samps := 0
var correction_delta := 1.0
func _physics_process(delta):
	if count_avg_samps == 0 or avg_buffer_size == 0 :
		correction_delta = 1.0
		return
	
	var half := float(lunghezza_buffer * 0.5)
	var avg := float(avg_buffer_size) / float(count_avg_samps)
	var temp_correction_delta = half / avg
#	print("Avg: ",avg)
#	print("Current length: ", buffer.size())
#	print("Correction delta: ",temp_correction_delta)
	correction_delta = lerpf(1.0,temp_correction_delta,correction_delta_amount)
#	print("Final correction: ",correction_delta)
	avg_buffer_size = 0
	count_avg_samps = 0


func sample_audio() -> float:
	avg_buffer_size += buffer.size()
	count_avg_samps += 1
	
	var out = buffer.pop_front()
	if out == null : return 0.0
	return out


func sample_reverb() -> float:
	return lunghezza_riverbero_attuale


func invia_campione(val_p: float, val_t : float, fase_albero : float):
	val_p *= moltiplicatore_pressione * 0.000001
	val_p = pow(val_p,esponenzialita_pressione)
	val_p = lerp(val_p, val_p * (randf()*2-1), rumorosita_pressione)
	
	val_t *= moltiplicatore_temperatura * 0.01
	val_t = pow(val_t,esponenzialita_temperatura)
	val_t = lerp(val_t, val_t * (randf()*2-1), rumorosita_temperatura)
	
	if use_valve and valve != null :
		valve.set_valve_position(fase_albero)
		valve.set_pressure(val_p)
	
	_popola_buffer(val_p + val_t)



func imposta_riverbero(volume : float, temperatura : float):
	var vel_suono : float = sqrt(391*temperatura)
	
	lunghezza_riverbero_attuale = max(0.1, volume*44100000 / vel_suono)


#func imposta_riverbero_retrocompatibile(volume : float, pressione : float):
#	# Per la vecchia simulazione fisica
#	pressione = pressione + 1.0 / (0.000001 * contributo_riverbero_pressione)
#	imposta_riverbero(volume, pressione)


# TI PREGO SCRIVI MEGLIO QUI SOTTO \/\/\/

var ultimo_valore_buffer = 0.0
var contatore_resto_buffer := 0.0
var delta_time := Time.get_ticks_usec()
func _popola_buffer(val : float):
	var delta = float(Time.get_ticks_usec() - delta_time) / 1_000_000.0
	delta *= correction_delta
	delta_time = Time.get_ticks_usec()
	# Numero di campioni necessari a compensare la differenza di velocita
	# Tra simulazione fisica e simulazione audio.
	var campioni_compensazione_f : float\
		= delta * InfoAudio.frequenza_campionamento_hz

	# Stesso valore ma in int
	var campioni_compensazione_i : int\
		= floori(delta * InfoAudio.frequenza_campionamento_hz)

	# Il resto
	contatore_resto_buffer +=\
		campioni_compensazione_f - campioni_compensazione_i as float


	var numero_iterazioni := campioni_compensazione_f
	
	while contatore_resto_buffer >= 1.0 :
		numero_iterazioni += 1
		contatore_resto_buffer -= 1.0
	
	for i in range(numero_iterazioni):
		var n = lerp(ultimo_valore_buffer, val, i as float / numero_iterazioni)
		
		buffer.push_back(n)
	
	ultimo_valore_buffer = val
