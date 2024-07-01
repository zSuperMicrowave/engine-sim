extends ComponenteAudio
class_name DelayInterpolatoOttimizzato

var buffer : Array[float]
var puntatore_buffer := 0.0

@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_category("ComponenteAudio")
@export var componente_precedente : ComponenteAudio

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var dimensione_buffer_base := 5
@export_range(2,4000) var dimensione_buffer_massima := 200
var dimensione_buffer := dimensione_buffer_base
var velocita_attraversamento := 1.0
@export var tubo_chiuso := true
@export var ritarda_input := false
@export_range(0.0,1.0) var modulazione_buffer := 0.0
@export_range(0,44100) var lentezza_modulazine := 500
@export_range(0.05,2.0) var dettaglio_modulazione_buffer := 0.3

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_group("Debug e Test")
@export var silenzia_errori := false
@export var blocca_estensione_riverbero := false
@export var motore : ComponenteMotore = null
@export var i_pistone : int = -1


func _enter_tree():
	buffer.resize(dimensione_buffer_base * 2)


func sample_audio(samps : int) -> Array[float]:
	var buff := componente_precedente.sample_audio(samps)
	var rev_buf := componente_precedente.sample_reverb(samps)
	
	var out : Array[float] = []

	for r in range(samps) :
		aggiorna_riverbero(rev_buf[r])

	#	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
		var attenuazione = 1.0/(1.0+attenuazione_suono*0.001)


		var input : float =\
			buff[r] * moltiplicatore_input_output

		# CALCOLA ROBE UTILI PER OTTIMIZZAZIONE
		var idx_max := ceili(puntatore_buffer+0.5+velocita_attraversamento*0.5)
		var idx_min := floori(puntatore_buffer+0.5-velocita_attraversamento*0.5)
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
	#		var i_pos := clampi(idx_min + i, 0, dimensione_buffer-1)
	#		var i_neg := clampi(idx_min + i + dimensione_buffer, dimensione_buffer, dimensione_buffer*2-1)
			
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

			# ---------INPUT1--------
			if not ritarda_input :
				if ( motore == null || i_pistone < 0 || \
				motore.albero_motore.pistoni[i_pistone].fase_attuale \
				== ComponentePistone.ESPULSIONE ) :
					buffer[i_pos] += input
				else :
					buffer[i_pos] += input * 0.4
			# -----------------------
			
			# OUTPU
			risultato += buffer[i_pos] * mul
			peso_output += mul
			
			# ---------INPUT2--------
			if ritarda_input :
				if ( motore == null || i_pistone < 0 || \
				motore.albero_motore.pistoni[i_pistone].fase_attuale \
				== ComponentePistone.ESPULSIONE ) :
					buffer[i_pos] += input
				else :
					buffer[i_pos] += input * 0.4
			# -----------------------


		# OUTPUT
		risultato /= maxf(peso_output, 0.1)
		risultato *= moltiplicatore_input_output

		out.append(risultato)
	
	return out

var cnt := 0
func aggiorna_riverbero(nuovo_riverbero : float):
	cnt+=1
	nuovo_riverbero = maxf(nuovo_riverbero, 0.0)


	if modulazione_buffer > 0.0 :
		if cnt > lentezza_modulazine :
			modulazione_buffer 
			ridimensiona_buffer(maxi(lerpf(
				dimensione_buffer_base,
				nuovo_riverbero * dettaglio_modulazione_buffer,
				modulazione_buffer),2))
			cnt = 0


	if blocca_estensione_riverbero :
		nuovo_riverbero = minf(nuovo_riverbero,dimensione_buffer)

	# * 0.5 perché il buffer specificato è metà del totale cazzo in culo
	velocita_attraversamento = nuovo_riverbero * 0.5 / dimensione_buffer as float


func ridimensiona_buffer(nuova_dimensione : int):
	nuova_dimensione = clampi(nuova_dimensione,2,dimensione_buffer_massima)
	puntatore_buffer = fmod(puntatore_buffer * (nuova_dimensione as float)\
		/ dimensione_buffer as float, nuova_dimensione)
	
#	buffer = ridimensiona_array(buffer,nuova_dimensione*2)
	var buf1 := buffer.slice(0,dimensione_buffer-1)
	var buf2 := buffer.slice(dimensione_buffer,dimensione_buffer*2-1)
	buf1 = ridimensiona_array(buf1,nuova_dimensione)
	buf2 = ridimensiona_array(buf2,nuova_dimensione)

	buffer = buf1 + buf2
	dimensione_buffer = nuova_dimensione




func ridimensiona_array(arr : Array[float], nuova_grandezza : int):
	var passo := (nuova_grandezza-1) as float / (arr.size()-1) as float
	var nuovo_buffer : Array[float]
	nuovo_buffer.resize(nuova_grandezza)

	if nuova_grandezza > arr.size() :
		for i in range(nuova_grandezza):
			var flr := clampi(floori(i / passo), 0, arr.size()-1)
			var cel := clampi(ceili( i / passo), 0, arr.size()-1)
			
			nuovo_buffer[i] = lerpf(arr[flr],arr[cel], i/passo - flr)
	else :
		var div : Array[float]
		div.resize(nuova_grandezza)
		nuovo_buffer.fill(0.0)
		div.fill(0.0)
		for i in range(arr.size()):
			var flr := clampi(floori(i * passo), 0, nuova_grandezza-1)
			var cel := clampi(ceili( i * passo), 0, nuova_grandezza-1)
			
			nuovo_buffer[flr] += arr[i] * maxf(i*passo - flr, 0.0)
			nuovo_buffer[cel] += arr[i] * maxf(cel - i*passo, 0.0)
			
			div[flr] += maxf(i*passo - flr, 0.0)
			div[cel] += maxf(cel - i*passo, 0.0)
		
		for i in range(nuova_grandezza) :
			if is_zero_approx(div[i]) :
				nuovo_buffer[i] = 0.0
				continue
			nuovo_buffer[i] /= div[i]
	
	arr = nuovo_buffer
	
	return arr

func ridimensiona_array_ciclico(arr : Array[float], nuova_grandezza : int) -> Array[float]:
	var passo = nuova_grandezza as float / arr.size()
	var nuovo_buffer : Array[float]
	nuovo_buffer.resize(nuova_grandezza)
	
	if nuova_grandezza > arr.size():
		for i in range(nuova_grandezza):
			var idx = i / passo
			var flr = int(idx) % arr.size()
			var cel = (flr + 1) % arr.size()
			var t = idx - flr
			nuovo_buffer[int(i+passo*0.45) % nuova_grandezza] = lerp(arr[flr], arr[cel], t)
	else:
		for i in range(nuova_grandezza):
			var start_idx = int(i * (arr.size() / nuova_grandezza))
			var end_idx = int((i + 1) * (arr.size() / nuova_grandezza))
			var sum = 0.0
			for j in range(start_idx, end_idx):
				sum += arr[j % arr.size()]
			nuovo_buffer[i] = sum / (end_idx - start_idx)

	return nuovo_buffer
