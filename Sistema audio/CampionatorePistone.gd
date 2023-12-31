@icon("./CampionatorePistone.gd.png")
extends ComponenteAudio
class_name CampionatorePistone

@export_category("CampionatorePistone")
#@export var motore : FisicaMotore
#@export var cilindro : int

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
var lunghezza_riverbero_attuale : float = 0.0

@export_group("Buffer")
@export var lunghezza_buffer : int = 11025
# Quanto il puntatore scrittura del buffer partirà in avanti relativamnete alla
# lunghezza totale del buffer. Serve per evitare aggiornamenti di valori del
# buffer che stanno per esser letti.
@export_range(0.0, 1.0) var avanzamento_puntatore_scrittura : float = 0.1

var buffer : BufferLetturaAudio = null


func _enter_tree():
	buffer = BufferLetturaAudio.new(lunghezza_buffer,avanzamento_puntatore_scrittura)


func ottieni_campione() -> float:
	return buffer.leggi()


func ottieni_riverbero() -> float:
	return lunghezza_riverbero_attuale


func invia_campione(val_p: float, val_t : float, delta : float):
	val_p *= moltiplicatore_pressione * 0.000001
	val_p = pow(val_p,esponenzialita_pressione)
	val_p = lerp(val_p, val_p * (randf()*2-1), rumorosita_pressione)
	
	val_t *= moltiplicatore_temperatura * 0.01
	val_t = pow(val_t,esponenzialita_temperatura)
	val_t = lerp(val_t, val_t * (randf()*2-1), rumorosita_temperatura)
	
	_popola_buffer(val_p + val_t, delta)


func imposta_riverbero(volume : float, pressione : float):
	volume = volume * 86800
	pressione = pressione * 0.000001 * contributo_riverbero_pressione
	
	if volume < 1.0 : volume = 1.0
	if pressione < 1.0 : pressione = 1.0
	
	lunghezza_riverbero_attuale = volume/pressione


func imposta_riverbero_retrocompatibile(volume : float, pressione : float):
	# Per la vecchia simulazione fisica
	pressione = pressione + 1.0 / (0.000001 * contributo_riverbero_pressione)
	imposta_riverbero(volume, pressione)


# TI PREGO SCRIVI MEGLIO QUI SOTTO \/\/\/

var ultimo_valore_buffer = 0.0
var contatore_resto_buffer := 0.0
func _popola_buffer(val : float, delta : float):
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
		
		buffer.scrivi(n)
	
	ultimo_valore_buffer = val
