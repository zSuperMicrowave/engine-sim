extends ComponenteAudio
class_name DelayInterpolato

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
	velocita_attraversamento = 5.0
	var arr = [1,1,1,1,1,1,1,1,1,1,1]
	attenua_buffer_per_indice(arr,0.0,0.0)
	print(arr, velocita_attraversamento)
	direzione_positiva_passaggi.resize(dimensione_buffer)
	direzione_negativa_passaggi.resize(dimensione_buffer)


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
	var risultato = direzione_positiva_passaggi[fposmod(roundi(puntatore_buffer),dimensione_buffer)]
	risultato *= moltiplicatore_input_output

	return risultato


func avanza_puntatori():
	puntatore_buffer += velocita_attraversamento


func applica_attenuazione(attenuazione : float):
	attenua_buffer_per_indice(direzione_positiva_passaggi, puntatore_buffer, attenuazione)
	attenua_buffer_per_indice(direzione_negativa_passaggi,\
		fposmod(-puntatore_buffer, dimensione_buffer), attenuazione)


func scambia_valori():
	scambia_valori_indice(puntatore_buffer)


func input_valori(input : float):
	input_porcodio(puntatore_buffer,input)


func aggiorna_riverbero():
	var nuovo_riverbero : float = componente_precedente.ottieni_riverbero()
	nuovo_riverbero = max(nuovo_riverbero,0.0)

	velocita_attraversamento = dimensione_buffer as float / nuovo_riverbero


#func campiona_buffer(arr : Array, idx : float):
#	if idx < 0:
#		printerr("Errore, stai campionando un buffer 
#			specificando un indice minore di zero")
#		return 0.0
#	if arr.size() < idx :
#		printerr("Errore, stai campionando un buffer la 
#			cui lunghezza è minore dell'indice specificato")
#		return 0.0
#
#	var range := ceili(velocita_attraversamento)
#	for i in range(range) :
#		var mul = 2 * abs(i - idx) / range
#
#	var i_a := floori(idx)
#	var i_b := ceili(idx) % arr.size()
#
#	return lerpf(arr[i_a],arr[i_b],idx - i_a)


func attenua_buffer_per_indice(arr : Array, idx : float, attenuazione : float):
#	if idx < 0:
#		printerr("Errore, stai campionando un buffer 
#			specificando un indice minore di zero")
#		return 0.0
#	if arr.size() < idx :
#		printerr("Errore, stai campionando un buffer la 
#			cui lunghezza è minore dell'indice specificato")
#		return 0.0


	var idx_max := ceili(idx+velocita_attraversamento*0.5)
	var idx_min := floori(idx-velocita_attraversamento*0.5)
	var range := idx_max - idx_min
	
	for i in range(range) :
		var mul := 1.0
		if i + idx_min < idx :
			mul = 2 * max(idx - (idx_min + i), 0.0) / range
		else :
			mul = 2 * max((idx_min + i) - idx, 0.0) / range
		
		arr[(idx_min + i) as int % dimensione_buffer] *= lerpf(attenuazione,1.0, mul)
#
#	var i_a := floori(idx)
#	var i_b := ceili(idx) % arr.size()
#
#	arr[i_a] *= lerpf(1.0,attenuazione,idx - i_a)
#	arr[i_b] *= lerpf(1.0,attenuazione,i_b - idx)


func scambia_valori_indice(idx : float):
	var idx_min := floori(idx-velocita_attraversamento*0.5)
	var idx_max := ceili(idx+velocita_attraversamento*0.5)
	var range := idx_max - idx_min
	
	for i in range(range) :
		var mul := 1.0
		if i + idx_min < idx :
			mul = 2 * max(idx - (idx_min + i), 0.0) / range
		else :
			mul = 2 * max((idx_min + i) - idx, 0.0) / range
		
		var i_pos := (idx_min + i) as int % dimensione_buffer
		var i_neg := (-idx_min -i) as int % dimensione_buffer
		
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


func input_porcodio(idx : int, input : float) :
	var idx_min := floori(idx-velocita_attraversamento*0.5)
	var idx_max := ceili(idx+velocita_attraversamento*0.5)
	var range := idx_max - idx_min
	
	for i in range(range) :
		var mul := 1.0
		if i + idx_min < idx :
			mul = 2 * max(idx - (idx_min + i), 0.0) / range
		else :
			mul = 2 * max((idx_min + i) - idx, 0.0) / range
		
		direzione_positiva_passaggi[(idx_min + i) as int % dimensione_buffer] += input
