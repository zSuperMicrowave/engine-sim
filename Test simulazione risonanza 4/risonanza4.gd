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

@onready var numero_passaggi := numero_passaggi_desiderato

var richiesta_cambio_dimensioni_array := false

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]

var i_buffer_positivo := 0
var i_buffer_negativo := 0

@export var moltiplicatore_energia_rimbalzo := 0.8
@export_range(0.0,1.0) var ovattamento_suono := 0.1
@export var attenuazione_suono := 1.0
@export var campioni_ovattamento_massimi := 30
@export_range(0.0,1.0) var percentuale_delta := 0.0 :
	set(valore):
		_reimposta_buffer()
		percentuale_delta = valore
@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0 :
	set(valore):
		_reimposta_buffer()
		moltiplicatore_input_output = valore


func _reimposta_buffer():
	for i in range(numero_passaggi):
		direzione_positiva_passaggi[i] = 0.0
		direzione_negativa_passaggi[i] = 0.0
		input_precedente = 0.0
		output_precedente = 0.0


func _ricalcola_dimensioni_array():
	numero_passaggi = numero_passaggi_desiderato
	direzione_positiva_passaggi.resize(numero_passaggi)
	direzione_negativa_passaggi.resize(numero_passaggi)
	i_buffer_negativo = i_buffer_negativo % numero_passaggi
	i_buffer_positivo = i_buffer_positivo % numero_passaggi
	
	
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


var input_precedente := 0.0
var output_precedente := 0.0


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
		
		i_buffer_positivo += 1
		if i_buffer_positivo >= numero_passaggi:
			i_buffer_positivo = 0
		
		i_buffer_negativo -= 1
		if i_buffer_negativo <= 0:
			i_buffer_negativo = numero_passaggi - 1


		# ATTENUAZIONE
		direzione_negativa_passaggi[i_buffer_negativo] *= attenuazione
		direzione_positiva_passaggi[i_buffer_positivo] *= attenuazione


		# SCAMBIO
		var temp_neg = direzione_negativa_passaggi[i_buffer_negativo]
		
		direzione_negativa_passaggi[i_buffer_negativo] =\
			 direzione_positiva_passaggi[i_buffer_positivo] * moltiplicatore_energia_rimbalzo
		
		direzione_positiva_passaggi[i_buffer_positivo] =\
			 temp_neg * moltiplicatore_energia_rimbalzo


		# INPUT
		direzione_positiva_passaggi[i_buffer_positivo] += input - input_precedente * percentuale_delta
		input_precedente = input


		# OUTPUT
		var risultato = 0.0
		for i in range(ampiezza_ovattamento):
			var sex = fmod(i_buffer_positivo + i, numero_passaggi)
			risultato += direzione_positiva_passaggi[sex]
		risultato /= ampiezza_ovattamento
		risultato *= moltiplicatore_input_output


		output_precedente = (output_precedente + risultato) * percentuale_delta  + risultato * (1.0 - percentuale_delta)
		playback.push_frame(Vector2.ONE * output_precedente)
		
		#print(risultato)
		tempi_elaborazione.push_back(Time.get_ticks_usec()-tick_inizio)
		
		da_riempire -= 1


func _physics_process(delta: float) -> void:
	_riempi_buffer()
	
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
