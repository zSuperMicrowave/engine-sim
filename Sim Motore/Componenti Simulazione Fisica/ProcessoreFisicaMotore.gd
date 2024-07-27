@icon("res://Sim Motore/Componenti Simulazione Fisica/icona-aggiornamento-motore.png")
extends Node
class_name ProcessoreFisicaMotore

const COMPENSAZIONE_USEC_CICLO_WHILE = 7

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


#func _ready():
#	Thread.new().start(_elabora.bind(),Thread.PRIORITY_HIGH)

var cnt := 0
func _elabora(amount : int):
	for i in range(amount) :
		cnt+= 1
		if cnt > frequenza_aggiornamento_hz / 30 :
			_elabora_lento(1.0/30.0)
			cnt = 0
		
		var delta : float = durata_frame_fisico_usec * 0.000001
		if Input.is_action_pressed("rallenta_fisica") :
			delta *= rallentamento_slow_motion
		for motore in motori:
			motore._elabora_rapido(delta)
#
#	var tempo_inizio_delta = Time.get_ticks_usec()
#	var delta := 0.0
#	while(true) :
#		var tempo_inizio = Time.get_ticks_usec()
#
#		# ELABORA
#		for motore in motori:
#			motore._elabora_rapido(delta)
#
#		# CALCOLA DELTA
#		if delta_fisso :
#			delta = durata_frame_fisico_usec as float / 1_000_000.0
#		else :
#			delta = (Time.get_ticks_usec() - tempo_inizio_delta) as float / 1_000_000.0
#		if Input.is_action_pressed("rallenta_fisica") :
#			delta *= rallentamento_slow_motion
#
#		tempo_inizio_delta = Time.get_ticks_usec()
#
#		while durata_frame_fisico_usec > Time.get_ticks_usec() - tempo_inizio :#+ COMPENSAZIONE_USEC_CICLO_WHILE:
#			continue


func _elabora_lento(delta : float):
	if Input.is_action_pressed("rallenta_fisica") :
			delta *= rallentamento_slow_motion
			Engine.time_scale = rallentamento_slow_motion
	else :
		Engine.time_scale = 1.0
	
	for motore in motori:
		motore._elabora_lento(delta)

var tempo_inizio_delta = Time.get_ticks_usec()

var t : Thread = Thread.new()
func _physics_process(delta):
	var da_elaborare : int = (Time.get_ticks_usec() - tempo_inizio_delta) / durata_frame_fisico_usec
	var old = da_elaborare
	da_elaborare = clampi(da_elaborare,0,frequenza_aggiornamento_hz*2)
	if old - da_elaborare > 0:
		print(old - da_elaborare)
	t.wait_to_finish()
	t.start(_elabora.bind(da_elaborare),Thread.PRIORITY_HIGH)
	tempo_inizio_delta = Time.get_ticks_usec()
