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

@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var numero_passaggi_desiderato := 5:
	set(valore):
		richiesta_cambio_dimensioni_buffer = true
		numero_passaggi_desiderato = valore
var richiesta_cambio_dimensioni_buffer := false
@onready var numero_passaggi := numero_passaggi_desiderato
@export var tubo_chiuso := true

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_subgroup("Ovattamento")
@export_range(0.0,1.0) var ovattamento_suono := 0.1
@export var campioni_ovattamento_massimi := 30

@export_group("Debug e Test")
@export_enum("NON FARE NULLA","TRONCA","SCALA","ESTENDI")\
	var metodo_restringimento_buffer := 1
@export_enum("NON FARE NULLA","TRONCA","SCALA","ESTENDI","SCALA PROPORZIONALMENTE")\
	var metodo_allargamento_buffer := 1
@export_enum("CICLA","SCALA")\
	var metodo_riposizionamento_buffer := 0
@export var grafico : Grafico2D = null
@export var monitora_prestazioni := false
var tempi_elaborazione := []


func _estendi_buffer(nuova_dimensione:int) -> void :
	var vecchio_buffer_positivo = direzione_positiva_passaggi.duplicate()
	var vecchio_buffer_negativo = direzione_negativa_passaggi.duplicate()
	direzione_positiva_passaggi.resize(nuova_dimensione)
	direzione_negativa_passaggi.resize(nuova_dimensione)

	var delta := 0
	var direzione_positiva_output = true
	var j := 0
	var direzione_positiva_input = true
	for i in range(nuova_dimensione*2) :
		j = i
		if i >= nuova_dimensione :
			direzione_positiva_output = !direzione_positiva_output
			delta += nuova_dimensione
		if j >= vecchio_buffer_positivo.size() :
			direzione_positiva_input = !direzione_positiva_input
			j = 0.0
		
		var val = 0.0
		
		if direzione_positiva_input :
			val = vecchio_buffer_positivo[j]
		else :
			val = vecchio_buffer_negativo[j]
		
		if direzione_positiva_output :
			direzione_positiva_passaggi[i - delta] = val
		else :
			direzione_negativa_passaggi[i - delta] = val


func _scala_proporzionalmente_array(array:Array, nuova_dimensione:int) -> void:
	if array.size() == nuova_dimensione :
		return
	if array.size() > nuova_dimensione :
		printerr("Non si può scalare proporzionalmente a diminuire")
		_scala_array(array,nuova_dimensione)
		return

	var vecchio_array = array.duplicate()
	array.resize(nuova_dimensione)
	
	var rapporto :=\
		vecchio_array.size() as float / nuova_dimensione as float
		
	var j := 0
	var contatore := 0.0
	for i in range(array.size()):
		if j < vecchio_array.size()-1 :
			array[i] = vecchio_array[j] * (1.0 - contatore)\
				+ vecchio_array[j+1] * contatore
		else :
			array[i] = vecchio_array[j]
		
		contatore += rapporto
		while contatore >= 1.0 :
			contatore -= 1.0
			j += 1

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
	if numero_passaggi == numero_passaggi_desiderato:
		richiesta_cambio_dimensioni_buffer = false
		return

	var rapporto = numero_passaggi_desiderato / numero_passaggi

	if rapporto > 1.0 :
		match metodo_allargamento_buffer :
			1:
				direzione_positiva_passaggi.resize(numero_passaggi_desiderato)
				direzione_negativa_passaggi.resize(numero_passaggi_desiderato)
			2:
				_scala_array(direzione_positiva_passaggi, numero_passaggi_desiderato)
				_scala_array(direzione_negativa_passaggi, numero_passaggi_desiderato)
			3:
				_estendi_buffer(numero_passaggi_desiderato)
			4:
				_scala_proporzionalmente_array(
					direzione_positiva_passaggi, numero_passaggi_desiderato)
				_scala_proporzionalmente_array(
					direzione_negativa_passaggi, numero_passaggi_desiderato)
	else :
		match metodo_restringimento_buffer :
			1:
				direzione_positiva_passaggi.resize(numero_passaggi_desiderato)
				direzione_negativa_passaggi.resize(numero_passaggi_desiderato)
			2:
				_scala_array(direzione_positiva_passaggi, numero_passaggi_desiderato)
				_scala_array(direzione_negativa_passaggi, numero_passaggi_desiderato)
			3:
				_estendi_buffer(numero_passaggi_desiderato)


	match metodo_riposizionamento_buffer :
		0:
			i_buffer_negativo %= numero_passaggi_desiderato
			i_buffer_positivo %= numero_passaggi_desiderato
		1:
			i_buffer_negativo *= rapporto
			i_buffer_positivo *= rapporto

	numero_passaggi = numero_passaggi_desiderato
	richiesta_cambio_dimensioni_buffer = false


func _test():
	print("AVVIO TEST...")
	var d = 10
	var d2 = d *2
	var arr = []
	for i in range(d) :
		arr.push_back(randi_range(0,10))

	print("Array di partenza:")
	print(arr)

	_scala_proporzionalmente_array(arr, d2)

	print("Array risultato:")
	print(arr)


func _ready():
	_test()
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
