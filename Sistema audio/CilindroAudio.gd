extends ComponenteAudio
class_name CilindroAudio

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]
var i_buffer_positivo := 0
var i_buffer_negativo := 0
var resto_puntatori := 0.0

@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_category("ComponenteAudio")
@export var componente_precedente : ComponenteAudio

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var dimensione_coda := 5
var velocita_attraversamento := 1.0
var velocita_attraversamento_int := 1
@export var tubo_chiuso := true

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_group("Debug e Test")
@export var silenzia_errori := false


func _enter_tree():
	direzione_positiva_passaggi.resize(dimensione_coda)
	direzione_negativa_passaggi.resize(dimensione_coda)


func ottieni_campione() -> float:
	aggiorna_riverbero()

	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
	var attenuazione = 1.0/(1.0+attenuazione_suono*0.001)


	var input : float =\
		componente_precedente.ottieni_campione() * moltiplicatore_input_output

	# AGGIORNA POSIZIONI DEI PUNTATORI
	avanza_puntatori()


	# ATTENUAZIONE
	applica_attenuazione(attenuazione)


	# SCAMBIO
	scambia_valori()

	# INPUT
	input_valori(input)


	# OUTPUT
	var risultato = direzione_positiva_passaggi[i_buffer_positivo]
	risultato *= moltiplicatore_input_output

	return risultato


func avanza_puntatori():
	var vel : int = velocita_attraversamento_int
	resto_puntatori += velocita_attraversamento - velocita_attraversamento_int
	if resto_puntatori >= 1.0 :
		resto_puntatori = 0.0
		vel += 1

	i_buffer_positivo += vel
	if i_buffer_positivo >= dimensione_coda:
		i_buffer_positivo = 0
	
	i_buffer_negativo -= vel
	if i_buffer_negativo <= 0:
		i_buffer_negativo = dimensione_coda - 1


func applica_attenuazione(attenuazione : float):
	for i in range(velocita_attraversamento_int+1) :
		var nuovo_i_negativo = fmod(i_buffer_negativo + i,dimensione_coda)
		var nuovo_i_positivo = dimensione_coda - 1 - nuovo_i_negativo
		
		
		if i == velocita_attraversamento :
			direzione_negativa_passaggi[nuovo_i_negativo] *=\
				lerpf(attenuazione,1.0,resto_puntatori)
			direzione_positiva_passaggi[nuovo_i_positivo] *=\
				lerpf(attenuazione,1.0,resto_puntatori)
		else :
			direzione_negativa_passaggi[nuovo_i_negativo] *= attenuazione
			direzione_positiva_passaggi[nuovo_i_positivo] *= attenuazione


func scambia_valori():
	for i in range(velocita_attraversamento_int+1) :
		var nuovo_i_negativo = fmod(i_buffer_negativo + i,dimensione_coda)
		var nuovo_i_positivo = dimensione_coda - 1 - nuovo_i_negativo
		
		
		if i == velocita_attraversamento :
			var temp_neg = direzione_negativa_passaggi[nuovo_i_negativo]
			
			direzione_negativa_passaggi[nuovo_i_negativo] = lerpf(
				direzione_negativa_passaggi[nuovo_i_negativo],
				direzione_positiva_passaggi[nuovo_i_positivo] * moltiplicatore_energia_rimbalzo,
				resto_puntatori)
			
			if tubo_chiuso :
				direzione_negativa_passaggi[nuovo_i_negativo] = lerpf(
					direzione_negativa_passaggi[nuovo_i_negativo],
					direzione_negativa_passaggi[nuovo_i_negativo] * -1,
					resto_puntatori)
			
			direzione_positiva_passaggi[nuovo_i_positivo] = lerpf(
				direzione_positiva_passaggi[nuovo_i_positivo],
				temp_neg * moltiplicatore_energia_rimbalzo,
				resto_puntatori)
		else :
			var temp_neg = direzione_negativa_passaggi[nuovo_i_negativo]
			
			direzione_negativa_passaggi[nuovo_i_negativo] =\
				 direzione_positiva_passaggi[nuovo_i_positivo] * moltiplicatore_energia_rimbalzo
			
			if tubo_chiuso : direzione_negativa_passaggi[nuovo_i_negativo] *= -1
			
			direzione_positiva_passaggi[nuovo_i_positivo] =\
				 temp_neg * moltiplicatore_energia_rimbalzo


func input_valori(input : float):
	for i in range(velocita_attraversamento_int+1) :
		var nuovo_i_negativo = fmod(i_buffer_negativo + i,dimensione_coda)
		var nuovo_i_positivo = dimensione_coda - 1 - nuovo_i_negativo
		
		if i == velocita_attraversamento :
			direzione_positiva_passaggi[nuovo_i_positivo] += input * resto_puntatori
		else :
			direzione_positiva_passaggi[nuovo_i_positivo] += input


func aggiorna_riverbero():
	var nuovo_riverbero : int = componente_precedente.ottieni_riverbero()

	if nuovo_riverbero > dimensione_coda :
		dimensione_coda = nuovo_riverbero
		direzione_positiva_passaggi.resize(dimensione_coda)
		direzione_negativa_passaggi.resize(dimensione_coda)
		i_buffer_negativo = fmod(i_buffer_negativo,dimensione_coda)
		i_buffer_positivo = fmod(i_buffer_positivo,dimensione_coda)

	velocita_attraversamento = dimensione_coda as float / nuovo_riverbero as float
	velocita_attraversamento_int = floori(velocita_attraversamento)
