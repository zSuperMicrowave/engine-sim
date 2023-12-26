extends AudioStreamPlayer
class_name RisonanzaBufferizzataAudioPlayerVecchio


@export var frequenza_campionamento := 44100
var playback : AudioStreamGeneratorPlayback

var contatore_resto := 0.0
var ultimo_campione_fisico := 0.0

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]
var i_buffer_positivo := 0
var i_buffer_negativo := 0

@export_group("Impostazioni Tubo")
@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_subgroup("Riverbero primario")
@export_range(2,4000) var numero_passaggi_desiderato := 5:
	set(valore):
		richiesta_cambio_dimensioni_buffer = true
		numero_passaggi_desiderato = valore
var richiesta_cambio_dimensioni_buffer := false
@onready var numero_passaggi := numero_passaggi_desiderato
@export var tubo_chiuso := true

@export_subgroup("Ovattamento")
@export_range(0.0,1.0) var ovattamento_suono := 0.1
@export var campioni_ovattamento_massimi := 30

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_group("Debug e Test")
@export_enum("METODO A","METODO B") var metodo_ridimensionamento_buffer := 0
@export_enum("METODO A","METODO B") var metodo_riposizionamento_buffer := 0
@export var grafico : Grafico2D = null
@export var monitora_prestazioni := false
var tempi_elaborazione := []


#func _estendi_array(array:Array, nuova_dimensione:int) -> void :
#	if array.size() == nuova_dimensione :
#		return array
#
#	var contatore_
#	while 


func _scala_array(array:Array, nuova_dimensione:int) -> void:
	if array.size() == nuova_dimensione :
		return

	var vecchio_array = array.duplicate()
	array.resize(nuova_dimensione)
	
	var rapporto :=\
		vecchio_array.size() as float / nuova_dimensione as float
		
	var j := 0
	var contatore := 0.0
	for i in range(array.size()):
		array[i] = vecchio_array[j]
		
		contatore += rapporto
		while contatore >= 1.0 :
			contatore -= 1.0
			j += 1


func _ricalcola_dimensioni_array() :
	var rapporto = numero_passaggi_desiderato / numero_passaggi
	numero_passaggi = numero_passaggi_desiderato

	match metodo_ridimensionamento_buffer :
		0:
			direzione_positiva_passaggi.resize(numero_passaggi)
			direzione_negativa_passaggi.resize(numero_passaggi)
		1:
			_scala_array(direzione_positiva_passaggi, numero_passaggi)
			_scala_array(direzione_negativa_passaggi, numero_passaggi)

	match metodo_riposizionamento_buffer :
		0:
			i_buffer_negativo %= numero_passaggi
			i_buffer_positivo %= numero_passaggi
		1:
			i_buffer_negativo *= rapporto
			i_buffer_positivo *= rapporto

	richiesta_cambio_dimensioni_buffer = false


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


func _physics_process(delta):
	if !playing:
		play()
		print("/!\\AUDIO BLOCCATO/!\\")
	
	if monitora_prestazioni:
		var media = 0.0
		for t in tempi_elaborazione :
			media += t
		media /= tempi_elaborazione.size()
		tempi_elaborazione = []
		print("[]MONITOR TEMPI ELABORAZIONE ON: ")
		print("  |Per campione: ",
			media," usec")
		print("  |Per ",frequenza_campionamento," campioni: ",
			media * frequenza_campionamento * 0.00_000_1," sec")


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
			
			
			if grafico :
				grafico.invia_dato(n)
	
	
	ultimo_campione_fisico = nuovo_campione


func ottieni_campione(input : float):
	var tick_inizio = Time.get_ticks_usec()
	
	var delta = 1.0 / stream.mix_rate
	
	var attenuazione = 1.0/(1.0+attenuazione_suono*numero_passaggi*0.0001)

	var ampiezza_ovattamento : int = ovattamento_suono *\
		clamp(numero_passaggi,0,campioni_ovattamento_massimi-1) + 1


	if richiesta_cambio_dimensioni_buffer:
		_ricalcola_dimensioni_array()
	
	
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


	# INPUT
	direzione_positiva_passaggi[i_buffer_positivo] += input


	# OUTPUT
	var risultato = 0.0
	for i in range(ampiezza_ovattamento):
		var sex = fmod(i_buffer_positivo + i, numero_passaggi)
		risultato += direzione_positiva_passaggi[sex]
	risultato /= ampiezza_ovattamento
	risultato *= moltiplicatore_input_output

	
	if monitora_prestazioni :
		tempi_elaborazione.push_back(Time.get_ticks_usec()-tick_inizio)
	
	return risultato
