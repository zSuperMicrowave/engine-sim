extends Node3D

var moltiplicatore_energia_rimbalzo := 0.9
var puntatore_arr := 0
var velocita_attraversamento := 1.1
var tubo_chiuso := false
var ritarda_input := false

func _ready():
	var nuova_grandezza = 16
	var arr : Array[float] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
#	print(arr)
#	print(ridimensiona_array(arr, nuova_grandezza))
	print(arr)
	for i in range(arr.size()*0.9) :
		ottieni_campione(i,arr)
	print(arr)
	puntatore_arr = 0
	for i in range(arr.size()*0.9) :
		ottieni_campione(-i,arr)
	print(arr)

func ridimensiona_array(arr : Array[float], nuova_grandezza : int) -> Array[float]:
	var passo = nuova_grandezza as float / arr.size()
	var nuovo_arr : Array[float]
	nuovo_arr.resize(nuova_grandezza)
	
	if nuova_grandezza > arr.size():
		for i in range(nuova_grandezza):
			var idx = i / passo
			var flr = int(idx) % arr.size()
			var cel = (flr + 1) % arr.size()
			var t = idx - flr
			nuovo_arr[int(i+passo*0.45) % nuova_grandezza] = lerp(arr[flr], arr[cel], t)
	else:
		for i in range(nuova_grandezza):
			var start_idx = int(i * (arr.size() / nuova_grandezza))
			var end_idx = int((i + 1) * (arr.size() / nuova_grandezza))
			var sum = 0.0
			for j in range(start_idx, end_idx):
				sum += arr[j % arr.size()]
			nuovo_arr[i] = sum / (end_idx - start_idx)

	return nuovo_arr


func ottieni_campione(input : float, arr : Array[float]) -> float:
	
	var dimensione_arr : int = arr.size() * 0.5

#	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
#	var attenuazione = 1.0/(1.0+attenuazione_suono*0.001)

	# CALCOLA ROBE UTILI PER OTTIMIZZAZIONE
	var idx_max := ceili(puntatore_arr+0.5+velocita_attraversamento*0.5)
	var idx_min := floori(puntatore_arr+0.5-velocita_attraversamento*0.5)
	var range := idx_max - idx_min
	var idx := puntatore_arr
	var risultato : float = 0.0
	var peso_output := 0.0


	# AGGIORNA POSIZIONI DEI PUNTATORI
	puntatore_arr =\
		fmod(puntatore_arr + velocita_attraversamento, dimensione_arr)


	# ATTENUAZIONE E SCAMBIO
	
	for i in range(range) :
		var mul := 1.0
		if i + idx_min < idx :
			mul = 2 * maxf(idx - (idx_min + i), 0.0) / range
		else :
			mul = 2 * maxf((idx_min + i) - idx, 0.0) / range
		
		# definisci cazzi
#		var i_pos := clampi(idx_min + i, 0, dimensione_arr-1)
#		var i_neg := clampi(idx_min + i + dimensione_arr, dimensione_arr, dimensione_arr*2-1)
		
		var i_pos := (idx_min + i) as int % dimensione_arr
		var i_neg := i_pos + dimensione_arr
		
#		var i_pos := ( (idx_min + i) as int ) % (dimensione_arr * 2)
#		var i_neg := (i_pos + dimensione_arr) % (dimensione_arr * 2)
		
		# ---------ATTENUA I VALORI---------
#		arr[i_pos] *= lerpf(attenuazione,1.0, mul)
#		arr[i_neg] *= lerpf(attenuazione,1.0, mul)
		#-----------------------------------

		# ---------SCAMBIA I VALORI---------
		var pos_temp := arr[i_pos]
		var neg_temp := arr[i_neg]
		
		if tubo_chiuso :
			arr[i_pos] = lerpf(
				pos_temp,
				neg_temp * -1 * moltiplicatore_energia_rimbalzo,
				mul)
				
			arr[i_neg] = lerpf(
				neg_temp,
				pos_temp * -1 * moltiplicatore_energia_rimbalzo,
				mul)
		else :
			arr[i_pos] = lerpf(
				pos_temp,
				neg_temp * moltiplicatore_energia_rimbalzo,
				mul)
				
			arr[i_neg] = lerpf(
				neg_temp,
				pos_temp * moltiplicatore_energia_rimbalzo,
				mul)
		#-----------------------------------

		# ---------INPUT1--------
		if not ritarda_input :
			arr[i_pos] += input
		# -----------------------
		
		# OUTPU
		risultato += arr[i_pos] * mul
		peso_output += mul
		
		# ---------INPUT2--------
		if ritarda_input :
			arr[i_pos] += input
		# -----------------------


	# OUTPUT
	risultato /= maxf(peso_output, 0.1)

	return risultato
