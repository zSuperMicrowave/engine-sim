extends AudioStreamPlayer


@export var audio : AudioStreamWAV

@export var mix_rate : int = 44100
@export var buffer_length : float = 0.25

var playback : AudioStreamPlayback = null

@export_range(2,100) var numero_passaggi := 5:
	set(valore):
		_ricalcola_dimensioni_array()
		numero_passaggi = valore

var direzione_positiva_passaggi : Array[float]
var nuova_direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]
var nuova_direzione_negativa_passaggi : Array[float]

@export var moltiplicatore_energia_rimbalzo := 0.8
@export var passaggio_output := 5
@export var ammortizzazione_suono := 0.1
@export var attenuazione_suono := 1.0

func _ricalcola_dimensioni_array():
	direzione_positiva_passaggi.resize(numero_passaggi)
	nuova_direzione_positiva_passaggi.resize(numero_passaggi)
	direzione_negativa_passaggi.resize(numero_passaggi)
	nuova_direzione_negativa_passaggi.resize(numero_passaggi)
	
	for i in range(numero_passaggi):
		direzione_positiva_passaggi[i] = 0.0
		nuova_direzione_positiva_passaggi[i] = 0.0
		direzione_negativa_passaggi[i] = 0.0
		nuova_direzione_negativa_passaggi[i] = 0.0


func _ready() -> void:
	_ricalcola_dimensioni_array()
	
	stream = AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = buffer_length
	
	play()
	
	playback = get_stream_playback()
	_riempi_buffer()

var t = 0.0
var tempi_elaborazione := []

func _riempi_buffer():
	var delta = 1.0 / stream.mix_rate
	
	var attenuazione = 1.0/(1.0+attenuazione_suono*0.0001)
	
	
	var da_riempire = playback.get_frames_available()
	#print(da_riempire)
	while da_riempire > 0:
		var tick_inizio = Time.get_ticks_usec()
		t += delta
		if t > 3.0:
			t = 0.0
		var ses = 0.0
		if fmod(t,2.0) >  1.0:
			ses = 1.0
		
		
		for i in range(numero_passaggi):

			var forza = 0.0
			if i == 0:
				# all'estremità positiva, fai rimbalzare il suono
				nuova_direzione_positiva_passaggi[i] = read_16bit_sample(audio) +\
					direzione_negativa_passaggi[i] * moltiplicatore_energia_rimbalzo

				nuova_direzione_negativa_passaggi[i] =direzione_negativa_passaggi[i+1]
			elif i == numero_passaggi -1:
				nuova_direzione_positiva_passaggi[i] = direzione_positiva_passaggi[i-1]

				# all'estremità ultima, fai rimbalzare il suono
				nuova_direzione_negativa_passaggi[i] =\
					direzione_positiva_passaggi[i] * moltiplicatore_energia_rimbalzo
			else:
				nuova_direzione_positiva_passaggi[i] = direzione_positiva_passaggi[i-1] * (1.0-ammortizzazione_suono)
				nuova_direzione_negativa_passaggi[i] = direzione_negativa_passaggi[i+1] * (1.0-ammortizzazione_suono)
				
				#riflessione suono
				nuova_direzione_positiva_passaggi[i] += direzione_positiva_passaggi[i+1] * ammortizzazione_suono
				nuova_direzione_negativa_passaggi[i] += direzione_negativa_passaggi[i-1] * ammortizzazione_suono
		
		for i in range(numero_passaggi):
			direzione_positiva_passaggi[i] = nuova_direzione_positiva_passaggi[i] * attenuazione
			direzione_negativa_passaggi[i] = nuova_direzione_negativa_passaggi[i] * attenuazione


		playback.push_frame(Vector2.ONE * direzione_positiva_passaggi[passaggio_output])
		tempi_elaborazione.push_back(Time.get_ticks_usec()-tick_inizio)
		da_riempire -= 1


# NON SO COSA SIA QUESTA FUNZIONE QUI SOTTO
#
#func interpola_verso_originale(i:float,delta:float):
#	nuova_direzione_positiva_passaggi[i] =\
#		direzione_positiva_passaggi[i] * delta +\
#		nuova_direzione_positiva_passaggi[i] * (1.0-delta)
#
#	nuova_direzione_negativa_passaggi[i] =\
#		direzione_negativa_passaggi[i] * delta +\
#		nuova_direzione_negativa_passaggi[i] * (1.0-delta)


func _physics_process(delta: float) -> void:
	
	_riempi_buffer()
	
	var media_tempi := 0.0
	for tempo in tempi_elaborazione:
		media_tempi += tempo
	media_tempi /= tempi_elaborazione.size()
	tempi_elaborazione = []
	
	print("Media temp elaborazione campione: ",media_tempi," uSec.")
	
	
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
	
	
	i_wav += 4 * rapporto
	
	return s

func _process(delta):
	if !playing :
		print("dio caneee")
		i_wav = 0
#	print(i_wav)
