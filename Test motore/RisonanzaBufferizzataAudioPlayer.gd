extends AudioStreamPlayer
class_name RisonanzaBufferizzataAudioPlayerVecchio


@export var frequenza_campionamento := 44100

@export var ancora_un_altro_grafico : Grafico2D

var playback : AudioStreamGeneratorPlayback

var contatore_resto := 0.0

var ultimo_campione_fisico := 0.0

@export var non_bestemmiare := false

@export_range(2,4000) var numero_passaggi_desiderato := 5:
	set(valore):
		richiesta_cambio_dimensioni_array = true
		numero_passaggi_desiderato = valore

@onready var numero_passaggi := numero_passaggi_desiderato
@export var passaggi_raggio_tubo := 3.0
@export var quantita_riverbero := 1
@export_range(0.01,0.75) var raggio_riverbero := 0.0

var richiesta_cambio_dimensioni_array := false

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]

var i_buffer_positivo := 0
var i_buffer_negativo := 0

@export var tubo_chiuso := true
@export var moltiplicatore_energia_rimbalzo := 0.8
@export_range(0.0,1.0) var ovattamento_suono := 0.1
@export var attenuazione_suono := 1.0
@export var campioni_ovattamento_massimi := 30
@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

var t = 0.0


func _ricalcola_dimensioni_array() :
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



func _ready():
	stream = AudioStreamGenerator.new()
	stream.mix_rate = frequenza_campionamento
	stream.buffer_length = 0.1
	play()
	playback = get_stream_playback()
	
	var frame_rimanenti := playback.get_frames_available()
	while frame_rimanenti > 0:
		playback.push_frame(Vector2.ONE)
		frame_rimanenti -= 1
	
	_ricalcola_dimensioni_array()


func _process(delta):
#	if buffer.size() != (stream.mix_rate * lunghezza_buffer_sec) as int :
#		buffer.resize((stream.mix_rate * lunghezza_buffer_sec) as int)
	if !playing:
		play()
		if !non_bestemmiare :
			print("porcodio")

#func _physics_process(delta):
#	var frame_rimanenti := playback.get_frames_available()
#	while frame_rimanenti > 0:
#		playback.push_frame(Vector2.ONE * buffer.leggi())
#		frame_rimanenti -= 1


func aggiungi_campione_fisico(nuovo_campione : float, delta : float):
	# Numero di campioni necessari a compensare la differenza di velocita
	# Tra simulazione fisica e simulazione audio.
	var campioni_compensazione : float = delta * stream.mix_rate

	# Stesso valore ma in int
	var campioni_compensazione_i = floori(delta * stream.mix_rate)

	# Il resto
	contatore_resto +=\
		campioni_compensazione - campioni_compensazione_i as float


	var numero_iterazioni := campioni_compensazione
	
	while contatore_resto >= 1.0 :
		numero_iterazioni += 1
		contatore_resto -= 1.0
	
	if playback.can_push_buffer(numero_iterazioni):
		for i in range(numero_iterazioni):
			var n = lerp(ultimo_campione_fisico, nuovo_campione, i as float / numero_iterazioni as float)
			
			#buffer.scrivi(n)
			playback.push_frame(Vector2.ONE * ottieni_campione(n))
			
			
			if ancora_un_altro_grafico :
				ancora_un_altro_grafico.invia_dato(n)
	
	
	ultimo_campione_fisico = nuovo_campione


func ottieni_campione(input : float):
	var delta = 1.0 / stream.mix_rate
	
	var attenuazione = 1.0/(1.0+attenuazione_suono*numero_passaggi*0.0001)

	var ampiezza_ovattamento : int = ovattamento_suono *\
		clamp(numero_passaggi,0,campioni_ovattamento_massimi-1) + 1


	if richiesta_cambio_dimensioni_array:
		_ricalcola_dimensioni_array()
	
	var tick_inizio = Time.get_ticks_usec()
	
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
	if tubo_chiuso : direzione_negativa_passaggi[i_buffer_negativo] *= -1
	
	direzione_positiva_passaggi[i_buffer_positivo] =\
		 temp_neg * moltiplicatore_energia_rimbalzo


	# RIVERBERO SECONDARIO
	for riverbero in range(quantita_riverbero):
		var i_riverbero : int = i_buffer_positivo - passaggi_raggio_tubo + passaggi_raggio_tubo * (1.0 / tan(riverbero*raggio_riverbero/quantita_riverbero+1))
		var buffer_positivo := true
#			print("sono fuori")
		while i_riverbero < 0 || i_riverbero >= numero_passaggi:
			if i_riverbero < 0 :
				buffer_positivo = true
#				print("sono bloccato ", i_riverbero)
			if buffer_positivo:
				buffer_positivo = false
				i_riverbero = -i_riverbero
			else:
				buffer_positivo = true
				i_riverbero = numero_passaggi - i_riverbero
		
		direzione_positiva_passaggi[i_buffer_positivo] *= 1.0 - attenuazione / (quantita_riverbero * 2)
		
		if buffer_positivo :
			direzione_positiva_passaggi[i_buffer_positivo] +=\
			direzione_positiva_passaggi[i_riverbero] * attenuazione / (quantita_riverbero * 2)
		else :
			direzione_positiva_passaggi[i_buffer_positivo] +=\
			direzione_negativa_passaggi[i_riverbero] * attenuazione / (quantita_riverbero * 2)


	# INPUT
	direzione_positiva_passaggi[i_buffer_positivo] += input


	# OUTPUT
	var risultato = 0.0
	for i in range(ampiezza_ovattamento):
		var sex = fmod(i_buffer_positivo + i, numero_passaggi)
		risultato += direzione_positiva_passaggi[sex]
	risultato /= ampiezza_ovattamento
	risultato *= moltiplicatore_input_output

	
	#print(risultato)
	tempi_elaborazione.push_back(Time.get_ticks_usec()-tick_inizio)
	
	return risultato
