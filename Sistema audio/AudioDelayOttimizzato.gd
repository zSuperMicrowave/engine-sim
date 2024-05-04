extends ComponenteAudio
class_name DelayInterpolatoOttimizzato

var buffer : Array[float]
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
@export var blocca_estensione_riverbero := false


func _enter_tree():
	buffer.resize(dimensione_buffer * 2)


func ottieni_campione() -> float:
	aggiorna_riverbero()

#	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
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
			mul = 2 * maxf(idx - (idx_min + i), 0.0) / range
		else :
			mul = 2 * maxf((idx_min + i) - idx, 0.0) / range
		
		# definisci cazzi
		var i_pos := (idx_min + i) as int % dimensione_buffer
		var i_neg := i_pos + dimensione_buffer
		
#		var i_pos := ( (idx_min + i) as int ) % (dimensione_buffer * 2)
#		var i_neg := (i_pos + dimensione_buffer) % (dimensione_buffer * 2)
		
		# ---------ATTENUA I VALORI---------
		buffer[i_pos] *= lerpf(attenuazione,1.0, mul)
		buffer[i_neg] *= lerpf(attenuazione,1.0, mul)
		#-----------------------------------

		# ---------SCAMBIA I VALORI---------
		var pos_temp := buffer[i_pos]
		var neg_temp := buffer[i_neg]
		
		if tubo_chiuso :
			buffer[i_pos] = lerpf(
				pos_temp,
				neg_temp * -1 * moltiplicatore_energia_rimbalzo,
				mul)
				
			buffer[i_neg] = lerpf(
				neg_temp,
				pos_temp * -1 * moltiplicatore_energia_rimbalzo,
				mul)
		else :
			buffer[i_pos] = lerpf(
				pos_temp,
				neg_temp * moltiplicatore_energia_rimbalzo,
				mul)
				
			buffer[i_neg] = lerpf(
				neg_temp,
				pos_temp * moltiplicatore_energia_rimbalzo,
				mul)
		#-----------------------------------

		# ---------INPUT---------
		buffer[i_pos] += input
		# -----------------------
		
		# OUTPU
		risultato += buffer[i_pos] * mul
		peso_output += mul


	# OUTPUT
	risultato /= maxf(peso_output, 0.1)
	risultato *= moltiplicatore_input_output

	return risultato


var cnt := 0
func aggiorna_riverbero():
	cnt+=1
	var nuovo_riverbero : float = componente_precedente.ottieni_riverbero()
	nuovo_riverbero = maxf(nuovo_riverbero, 0.0)
	if blocca_estensione_riverbero :
		nuovo_riverbero = minf(nuovo_riverbero,dimensione_buffer)

#	if cnt > InfoAudio.frequenza_campionamento_hz * 0.08 :
#		ridimensiona_buffer(max(floori(nuovo_riverbero*2.0),2))
#		cnt = 0

#	_scala_proporzionalmente_array(buffer,maxi(maxi(roundi(nuovo_riverbero),2)*2,2))
#	puntatore_buffer *= maxi(roundi(nuovo_riverbero),2)*2 as float / dimensione_buffer as float
#	dimensione_buffer = maxi(roundi(nuovo_riverbero),2)

	# * 0.5 perché il buffer specificato è metà del totale cazzo in culo
	velocita_attraversamento = nuovo_riverbero * 0.5 / dimensione_buffer as float


#func ridimensiona_buffer(nuova_dimensione : int):
#	var diff := nuova_dimensione*2 as float / dimensione_buffer as float
#	var nuovo_buffer : Array[float]
#	nuovo_buffer.resize(nuova_dimensione*2)
#
#	for i in range(dimensione_buffer):
#		var idx_max := ceili( i * diff + diff*0.5)
#		var idx_min := floori( i * diff - diff*0.5)
#		var range := idx_max - idx_min
#
#		for j in range(range) :
#			var idx := i * diff + j * diff / range
#			var mul := 1.0
#			if i + idx_min < idx :
#				mul = 2 * maxf(idx - (idx_min + i), 0.0) / range
#			else :
#				mul = 2 * maxf((idx_min + i) - idx, 0.0) / range
#
#			# definisci cazzi
#			nuovo_buffer[roundi(idx) % nuova_dimensione*2] = lerpf(buffer[i % dimensione_buffer],buffer[roundi(i + j * diff/range) % dimensione_buffer],mul)
##			var i_pos := (idx_min + i) as int % dimensione_buffer
##			var i_neg := i_pos + dimensione_buffer
#
#	dimensione_buffer = nuova_dimensione
#	buffer = nuovo_buffer
#
#	puntatore_buffer = fmod(puntatore_buffer,nuova_dimensione)
#
#func _scala_array(array:Array, nuova_dimensione:int) -> void:
#	if array.size() == nuova_dimensione :
#		return
#
#	var vecchio_array = array.duplicate()
#	array.resize(nuova_dimensione)
#
#	var rapporto :=\
#		vecchio_array.size() as float / nuova_dimensione as float
#
#	var j := 0
#	var contatore := 0.0
#	for i in range(array.size()):
#		array[i] = vecchio_array[j]
#
#		contatore += rapporto
#		while contatore >= 1.0 :
#			contatore -= 1.0
#			j += 1
#
#func _scala_proporzionalmente_array(array:Array, nuova_dimensione:int) -> void:
#	if array.size() == nuova_dimensione :
#		return
#	if array.size() > nuova_dimensione :
##		if !silenzia_errori :
##			printerr("Non si può scalare proporzionalmente a diminuire")
#		_scala_array(array,nuova_dimensione)
#		return
#
#	var vecchio_array = array.duplicate()
#	array.resize(nuova_dimensione)
#
#	var rapporto :=\
#		vecchio_array.size() as float / nuova_dimensione as float
#
#	var j := 0
#	var contatore := 0.0
#	for i in range(array.size()):
#		if j < vecchio_array.size()-1 :
#			array[i] = vecchio_array[j] * (1.0 - contatore)\
#				+ vecchio_array[j+1] * contatore
#		else :
#			array[i] = vecchio_array[j]
#
#		contatore += rapporto
#		while contatore >= 1.0 :
#			contatore -= 1.0
#			j += 1
