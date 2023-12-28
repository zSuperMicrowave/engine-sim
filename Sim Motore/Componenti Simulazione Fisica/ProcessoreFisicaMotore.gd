@icon("res://Sim Motore/Componenti Simulazione Fisica/icona-aggiornamento-motore.png")
extends Node
class_name ProcessoreFisicaMotore

const COMPENSAZIONE_USEC_CICLO_WHILE = 5

@export var motori : Array[ComponenteMotore]

@export_range(1,96000) var frequenza_aggiornamento_hz := 11025:
	set(valore):
		frequenza_aggiornamento_hz = valore
		@warning_ignore("integer_division")
		durata_frame_fisico_usec = 1_000_000/frequenza_aggiornamento_hz 
var durata_frame_fisico_usec : int = 1_000_000/frequenza_aggiornamento_hz
@export_range(0.001,0.5) var rallentamento_slow_motion := 0.01

@export_group("Debug")
@export var delta_fisso := false


func _ready():
	Thread.new().start(_elabora.bind(),Thread.PRIORITY_HIGH)


func _elabora():
	var tick_inizio_chiamata := 0
	var tick_delta_inizio_chiamata := 0
	var delta := 0.0
	while(true) :

		# Se non è passato abbastanza tempo continua a non fare niente
		while durata_frame_fisico_usec > Time.get_ticks_usec() - tick_inizio_chiamata + COMPENSAZIONE_USEC_CICLO_WHILE:
			continue

		tick_inizio_chiamata = Time.get_ticks_usec()

		for motore in motori:
			motore._elabora_fisica_motore(delta)

		if delta_fisso :
			delta = durata_frame_fisico_usec as float / 1_000_000.0
		else :
			delta = (Time.get_ticks_usec() - tick_delta_inizio_chiamata) as float / 1_000_000.0
		if Input.is_action_pressed("rallenta_fisica") :
			delta *= rallentamento_slow_motion

		tick_delta_inizio_chiamata = Time.get_ticks_usec()
