extends AudioStreamPlayer


@export var mix_rate : int = 44100
@export var buffer_length : float = 0.25

var playback : AudioStreamPlayback = null

@export_range(2,100) var numero_passaggi := 5:
	set(valore):
		_ricalcola_dimensioni_array()
		numero_passaggi = valore

@onready var posizione_passaggi := Array()
@onready var velocita_passaggi := Array()
@onready var nuova_posizione_passaggi := Array()

@export var inerzia := 1.0
@export var coefficiente_attrito = 0.1
@export var lunghezza_passaggio_mm = 1.0

func _ricalcola_dimensioni_array():
	posizione_passaggi.resize(numero_passaggi)
	velocita_passaggi.resize(numero_passaggi)
	nuova_posizione_passaggi.resize(numero_passaggi)
	
	for i in range(numero_passaggi):
		posizione_passaggi[i] = 0.0
		velocita_passaggi[i] = 0.1
		nuova_posizione_passaggi[i] = 0.0


func _ready() -> void:
	_ricalcola_dimensioni_array()
	
	stream = AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = buffer_length
	
	play()
	
	playback = get_stream_playback()

var t = 0.0

func _riempi_buffer():
	var delta = 1.0 / stream.mix_rate
	
	var da_riempire = playback.get_frames_available()
	
	while da_riempire > 0:
		t += delta
		var ses = 0.0
		if fmod(t,2.0) >  1.0:
			ses = 500.0

		for i in range(numero_passaggi):
			
			var forza = 0.0
			if i == 0:
				forza = posizione_passaggi[i+1]-posizione_passaggi[i]+(sin(t*440*TAU)+sin(t*880*TAU))*ses
			elif i == numero_passaggi -1:
				forza = posizione_passaggi[i-1]-posizione_passaggi[i]
			else:
				forza = (posizione_passaggi[i-1]+posizione_passaggi[i+1])*0.5 - posizione_passaggi[i]

			var forza_attrito = -velocita_passaggi[i] * coefficiente_attrito* 0.001
			
			velocita_passaggi[i] += ((forza+forza_attrito)/(inerzia*0.001)) * delta
			nuova_posizione_passaggi[i] = velocita_passaggi[i] * delta / (lunghezza_passaggio_mm*0.001)


		for i in range(numero_passaggi):
			posizione_passaggi[i] = nuova_posizione_passaggi[i]


		playback.push_frame(Vector2.ONE * posizione_passaggi[14] )
		
		da_riempire -= 1


func _physics_process(delta: float) -> void:
	_riempi_buffer()
	for i in range(numero_passaggi):
		print("passaggio ",i,": ", posizione_passaggi[i])
