extends AudioStreamPlayer
class_name BufferFisicaAudio


@export var lunghezza_buffer_sec := 1.0
@export var frequenza_campionamento := 44100

@export var ancora_un_altro_grafico : Grafico2D

var playback : AudioStreamGeneratorPlayback

var contatore_resto := 0.0

var ultimo_campione_fisico := 0.0

@onready var buffer := BufferCircolare.new(lunghezza_buffer_sec * frequenza_campionamento)

var t = 0.0

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


func _process(delta):
#	if buffer.size() != (stream.mix_rate * lunghezza_buffer_sec) as int :
#		buffer.resize((stream.mix_rate * lunghezza_buffer_sec) as int)
	if !playing:
		play()
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
			playback.push_frame(Vector2.ONE * n)
			
			
			if ancora_un_altro_grafico :
				ancora_un_altro_grafico.invia_dato(n)
	
	
	ultimo_campione_fisico = nuovo_campione
