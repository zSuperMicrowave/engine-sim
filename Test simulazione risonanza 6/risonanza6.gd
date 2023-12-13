extends AudioStreamPlayer

# |--------------
# | Simulazione risonanza suono in un tubo
# |--------------
# | Il suono si propaga lungo il tubo e quando raggiunge la fine si rilfette
# | e viene attenuato, poi quando raggiunge l'inizio si riflette di nuovo.
# | Nell'implementazione qui di sotto, il suono è un float che percorre un
# | array. In un implementazione più vicina alla realtà, possiamo immaginare
# | che tutti i float nell'array si spostino verso destra, e che quando
# | raggiungono la fine, vengano riflessi e spostati pian piano verso sinistra
# | in un secondo array di ritorno, in cui poi vengono ririflessi nel primo
# | con un po' di attenuazione.
# | Per ridurre il peso di questa implementazione, che costringerebbe a
# | Manipolare tutto l'array, nel codice di sotto si immagina che siano le
# | pareti a spostarsi e non il suono, pertanto i float conservati verranno
# | ad ogni iterazione scambiati tra i due array, poi verrà aggiunto l'input
# | all'array che scorre in avanti e campionato il suono nel medesimo
# | puntatore.
# | Infine, per "ovattare" il suono, in uscita questo viene campionato
# | sia dal puntatore che dai suoni lasciati in precedenza.
# |--------------



@export var audio : AudioStreamWAV

@export var mix_rate : int = 44100
@export var buffer_length : float = 0.25

var playback : AudioStreamPlayback = null

@export_range(2,4000) var numero_passaggi_desiderato := 5:
	set(valore):
		richiesta_cambio_dimensioni_array = true
		numero_passaggi_desiderato = valore

var numero_passaggi := numero_passaggi_desiderato
@export var passaggi_raggio_tubo := 3.0
@export var quantita_riverbero := 1
@export_range(0.01,0.75) var raggio_riverbero := 0.0

var richiesta_cambio_dimensioni_array := false

var array_passaggi : Array[float]
var indice_inizio_buffer_positivo := 0
var indice_inizio_buffer_negativo := numero_passaggi

var i_buffer := 0

@export var tubo_chiuso := true
@export var moltiplicatore_energia_rimbalzo := 0.8
@export_range(0.0,1.0) var ovattamento_suono := 0.1
@export var attenuazione_suono := 1.0
@export var campioni_ovattamento_massimi := 30
@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0


#func _reimposta_buffer():
#	for i in range(numero_passaggi):
#		direzione_positiva_passaggi[i] = 0.0
#		direzione_negativa_passaggi[i] = 0.0


func _ricalcola_dimensioni_array():
	
	if numero_passaggi_desiderato > numero_passaggi:
		i_buffer = (i_buffer + indice_inizio_buffer_positivo) % numero_passaggi_desiderato
		indice_inizio_buffer_positivo = 0
		
	elif numero_passaggi_desiderato < numero_passaggi:
		var differenza_passaggi = numero_passaggi - numero_passaggi_desiderato
		if i_buffer >= differenza_passaggi:
			indice_inizio_buffer_positivo = differenza_passaggi
		else:
			indice_inizio_buffer_positivo = i_buffer
		
	
	if indice_inizio_buffer_positivo + numero_passaggi_desiderato * 2 > array_passaggi.size():
			array_passaggi.resize(indice_inizio_buffer_positivo + numero_passaggi_desiderato * 2)
	
	
	indice_inizio_buffer_negativo = numero_passaggi_desiderato + indice_inizio_buffer_positivo
	
	
	numero_passaggi = numero_passaggi_desiderato
	richiesta_cambio_dimensioni_array = false
#	for i in range(numero_passaggi):
#		direzione_positiva_passaggi[i] = 0.0
#		direzione_negativa_passaggi[i] = 0.0

var tempi_elaborazione := []

func _ready() -> void:
	_ricalcola_dimensioni_array()
	
	stream = AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = buffer_length
	
	play()
	
	playback = get_stream_playback()
	_riempi_buffer()



func _riempi_buffer():
	var delta = 1.0 / stream.mix_rate
	
	var attenuazione = 1.0/(1.0+attenuazione_suono*numero_passaggi*0.0001)

	var ampiezza_ovattamento : int = ovattamento_suono *\
		clamp(numero_passaggi,0,campioni_ovattamento_massimi-1) + 1


	var da_riempire = playback.get_frames_available()
	#print(da_riempire)
	while da_riempire > 0:
		if richiesta_cambio_dimensioni_array:
			_ricalcola_dimensioni_array()
		
		var tick_inizio = Time.get_ticks_usec()
		
		var input := read_16bit_sample(audio)
		input *= moltiplicatore_input_output

		# AGGIORNA POSIZIONI DEI PUNTATORI
		
		i_buffer += 1
		if i_buffer >= numero_passaggi:
			i_buffer = 0


		# ATTENUAZIONE
		array_passaggi[indice_inizio_buffer_positivo + i_buffer] *= attenuazione
		array_passaggi[indice_inizio_buffer_negativo + i_buffer] *= attenuazione


		# RIVERBERO SECONDARIO
		for riverbero in range(quantita_riverbero):
			var i_riverbero : int = i_buffer - passaggi_raggio_tubo + passaggi_raggio_tubo * (1.0 / tan(riverbero*raggio_riverbero/quantita_riverbero+1))
#			print("sono fuori")
			while i_riverbero < 0 :
				i_riverbero += numero_passaggi * 2

			array_passaggi[indice_inizio_buffer_positivo + i_buffer] *= 1.0 - attenuazione / (quantita_riverbero * 2)

			array_passaggi[indice_inizio_buffer_positivo + i_buffer] +=\
			array_passaggi[i_riverbero] * attenuazione / (quantita_riverbero * 2)


		# SCAMBIO
		var temp_neg = array_passaggi[indice_inizio_buffer_negativo + i_buffer]
		
		array_passaggi[indice_inizio_buffer_negativo + i_buffer] =\
			 array_passaggi[indice_inizio_buffer_positivo + i_buffer] * moltiplicatore_energia_rimbalzo
		if tubo_chiuso : array_passaggi[indice_inizio_buffer_negativo + i_buffer] *= -1
		
		array_passaggi[indice_inizio_buffer_positivo + i_buffer] =\
			 temp_neg * moltiplicatore_energia_rimbalzo


		# INPUT
		array_passaggi[indice_inizio_buffer_positivo + i_buffer] += input


		# OUTPUT
		var risultato = 0.0
		for i in range(ampiezza_ovattamento):
			var sex = fmod(indice_inizio_buffer_positivo + i_buffer + i, numero_passaggi)
			risultato += array_passaggi[sex]
		risultato /= ampiezza_ovattamento
		risultato *= moltiplicatore_input_output


		playback.push_frame(Vector2.ONE * risultato)
		
		#print(risultato)
		tempi_elaborazione.push_back(Time.get_ticks_usec()-tick_inizio)
		
		da_riempire -= 1

#var t = 0.0

func _physics_process(delta: float) -> void:
	_riempi_buffer()
	
#	t += delta
#	numero_passaggi_desiderato = 150 + sin(t*TAU)*20
	
	#print(output_precedente)
	var media_tempi := 0.0
	for tempo in tempi_elaborazione:
		media_tempi += tempo
	media_tempi /= tempi_elaborazione.size()
	tempi_elaborazione = []
	
	
	#print("Media temp elaborazione campione: ",media_tempi," uSec.")
#	for i in range(numero_passaggi):
#		print("passaggio ",i,": ", direzione_positiva_passaggi[i])

var i_wav := 0
@onready var bytes = audio.data
@onready var rapporto = 44100/mix_rate


func read_16bit_sample(astream: AudioStreamWAV, reset := false) -> float:
	assert(astream.format == AudioStreamWAV.FORMAT_16_BITS)
	if i_wav > bytes.size() -1:
		i_wav = 0
	
	
	# Read by packs of 2 bytes
	var b0 = bytes[i_wav]
	var b1 = bytes[i_wav + 1]
	# Combine low bits and high bits to obtain 16-bit value
	var u = b0 | (b1 << 8)
	# Emulate signed to unsigned 16-bit conversion
	u = (u + 32768) & 0xffff
	# Convert to -1..1 range
	var s = float(u - 32768) / 32768.0
	
	if astream.stereo:
		i_wav += 4 * rapporto
	else:
		i_wav += 2 * rapporto
	
	return s

func _process(delta):
	if !playing :
		print("dio caneee")
		i_wav = 0
#	print(i_wav)
