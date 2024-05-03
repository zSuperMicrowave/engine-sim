extends ComponenteAudio
class_name DelayInterpolatoOttimizzato

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]
var puntatore_buffer := 0.0

@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_category("ComponenteAudio")
@export var componente_precedente : ComponenteAudio

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var dimensione_buffer := 5
var velocita_attraversamento := 1.0
@export var tubo_chiuso := true

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_group("Debug e Test")
@export var silenzia_errori := false


func _enter_tree():
	direzione_positiva_passaggi.resize(dimensione_buffer)
	direzione_negativa_passaggi.resize(dimensione_buffer)


func ottieni_campione() -> float:
	aggiorna_riverbero()

	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
	var attenuazione = 1.0/(1.0+attenuazione_suono*0.001)


	var input : float =\
		componente_precedente.ottieni_campione() * moltiplicatore_input_output

	# CALCOLA ROBE UTILI PER OTTIMIZZAZIONE
	var idx_max := ceili(puntatore_buffer+velocita_attraversamento*0.5)
	var idx_min := floori(puntatore_buffer-velocita_attraversamento*0.5)
	var range := idx_max - idx_min
	var idx := puntatore_buffer
	var risultato : float = 0.0
	var peso_output := 0.0


	# AGGIORNA POSIZIONI DEI PUNTATORI
	puntatore_buffer =\
		fmod(puntatore_buffer + velocita_attraversamento, dimensione_buffer)


	# ATTENUAZIONE E SCAMBIO
	
	for i in range(range) :
		var mul := 1.0
		if i + idx_min < idx :
			mul = 2 * max(idx - (idx_min + i), 0.0) / range
		else :
			mul = 2 * max((idx_min + i) - idx, 0.0) / range
		
		# definisci cazzi
		var i_pos := (idx_min + i) as int % dimensione_buffer
		var i_neg := (-idx_min -i) as int % dimensione_buffer
		
		# ---------ATTENUA I VALORI---------
		direzione_positiva_passaggi[i_pos] *= lerpf(attenuazione,1.0, mul)
		direzione_negativa_passaggi[i_neg] *= lerpf(attenuazione,1.0, mul)
		#-----------------------------------

		# ---------SCAMBIA I VALORI---------
		var temp := direzione_positiva_passaggi[i_pos]
		
		if tubo_chiuso :
			direzione_positiva_passaggi[i_pos] = lerpf(
				direzione_positiva_passaggi[i_pos],
				direzione_negativa_passaggi[i_neg] * -1 * moltiplicatore_energia_rimbalzo,
				mul)
				
			direzione_negativa_passaggi[i_neg] = lerpf(
				direzione_negativa_passaggi[i_neg],
				temp * -1 * moltiplicatore_energia_rimbalzo,
				mul)
		else :
			direzione_positiva_passaggi[i_pos] = lerpf(
				direzione_positiva_passaggi[i_pos],
				direzione_negativa_passaggi[i_neg] * moltiplicatore_energia_rimbalzo,
				mul)
				
			direzione_negativa_passaggi[i_neg] = lerpf(
				direzione_negativa_passaggi[i_neg],
				temp * moltiplicatore_energia_rimbalzo,
				mul)
		#-----------------------------------

		# ---------INPUT---------
		direzione_positiva_passaggi[i_pos] += input
		# -----------------------
		
		# OUTPU
		risultato += direzione_positiva_passaggi[i_pos] * mul
		peso_output += mul


	# OUTPUT
	risultato /= max(peso_output, 0.1)
	risultato *= moltiplicatore_input_output

	return risultato


func aggiorna_riverbero():
	var nuovo_riverbero : float = componente_precedente.ottieni_riverbero()
	nuovo_riverbero = max(nuovo_riverbero, 0.0)

	velocita_attraversamento = nuovo_riverbero / dimensione_buffer as float
