extends Node
class_name SincronizzatoreFisicaAudio

var thread_fisica : Thread

var durata_frame_fisico_usec := 0
@export_range(1,96000) var frequenza_fisica_hz := 11025:
	set(valore):
		frequenza_fisica_hz = valore
		@warning_ignore("integer_division")
		durata_frame_fisico_usec = 1_000_000/frequenza_fisica_hz

@onready var figli := get_children()


func _ready():
	thread_fisica = Thread.new()
	thread_fisica.start(_processa_fisica_audio.bind(),Thread.PRIORITY_HIGH)


var delta_fisica_audio := 0.0
var tempo_calcolo_cazzo := 0
var tick_inizio_chiamata := 0


func _processa_fisica_audio():

	while(true) :

		if (1_000_000.0 / frequenza_fisica_hz) as int > Time.get_ticks_usec() - tick_inizio_chiamata + 5:
			continue


		# Esegui il loop
		for figlio in figli :
			if figlio is NodoFisicaAudio :
				figlio._chiama_loop(delta_fisica_audio)


#		OS.delay_usec(
#			clamp( (1_000_000.0 / frequenza_fisica_hz) as int - (Time.get_ticks_usec() - tick_inizio_chiamata),
#			0,1_000_000)
#			)

		delta_fisica_audio = (Time.get_ticks_usec() - tick_inizio_chiamata) / 1_000_000.0
		if Input.is_action_pressed("rallenta_fisica") :
			delta_fisica_audio /= 100.0

		# Utile al calcolo del delta e attesa ciclo
		tick_inizio_chiamata = Time.get_ticks_usec()
