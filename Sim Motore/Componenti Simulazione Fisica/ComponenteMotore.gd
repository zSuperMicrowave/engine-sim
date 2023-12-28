@icon("res://Sim Motore/Componenti Simulazione Fisica/icona-motore.png")
extends Node
class_name ComponenteMotore

@export_category("Variabili_ambientali")
@export var temperatura_esterna := 300.15
@export var pressione_atmosferica := 101325

@export_category("Stato apparecchi")
@export var batteria_connessa := true
@export var coefficiente_attrito_meccanico_totale := 0.0
@export var carburante_attuale_litri := 10.0 

@export_category("Componenti")
@export var albero_motore : ComponenteAlberoMotore
@export var volano : ComponenteVolano
@export var ecu : ComponenteEcu

@export_category("Debug")
@export var velocita_debug_lento_hz := 5
@export var griglia_parametri : GrigliaDebugParametri
@export var pistoni_debug : Array[DebugPistone]
@export var audio : RisonanzaBufferizzataVecchio3D
@export var speedometer : Speedometer
@export var grafici : Node2D

@export_category("Audio")
@export_range(0.8,3.0) var compensazione_lentezza_simulazione := 1.5


var dbg_len := 0.0
var elab_ecu := 0.0

func _elabora_fisica_motore(delta: float) -> void :
	albero_motore.elabora(self, delta)
	
	ecu.elabora(self,delta)
	
	calcola_audio(delta)

	contatore += 1

	if dbg_len >=  1.0 / velocita_debug_lento_hz:
		call_deferred("_debug_lento")
		dbg_len = 0.0
		max_deltatime = 0.0
	dbg_len += delta
	if delta > max_deltatime :
		max_deltatime = delta
	call_deferred("_debug",delta)

var ultimo_errore_validazione_formula := 0.0
var max_deltatime := 0.0

func _debug_lento():
	if grafici :
		grafici.find_child("moli_carburante").invia_dato(albero_motore.pistoni[0].aria_cilindro.moli_benzina)
		grafici.find_child("moli_ossigeno").invia_dato(albero_motore.pistoni[0].aria_cilindro.moli_ossigeno)
		grafici.find_child("moli_scarico").invia_dato(albero_motore.pistoni[0].aria_cilindro.moli_gas_scarico)
		grafici.find_child("pressione").invia_dato(albero_motore.pistoni[0].aria_cilindro.pressione)
		grafici.find_child("rpm").invia_dato(albero_motore.velocita_angolare / Unita.rpm)
		grafici.find_child("temperatura").invia_dato(albero_motore.pistoni[0].aria_cilindro.temperatura)
		grafici.find_child("deltatime").invia_dato(max_deltatime*10-0.05)
		if max_deltatime > 0.001 :
			print("IL DELTA IL DELTA ANANGG: ", albero_motore.pistoni[0].fase_attuale)
	if speedometer :
		speedometer.rpm = albero_motore.velocita_angolare / Unita.rpm
	if griglia_parametri :
		var validita_formula = 1000 * albero_motore.pistoni[0].aria_cilindro.ottieni_validita_formula()
		if not is_equal_approx(validita_formula, 1000.0):
			ultimo_errore_validazione_formula = validita_formula
		griglia_parametri.scrivi_parametro("RPM", albero_motore.velocita_angolare / Unita.rpm)
#		griglia_parametri.scrivi_parametro("RPM motorino avviatore"
#			, albero_motore.motorino_avviamento.velocita_attuale / Unita.rpm)
		griglia_parametri.scrivi_parametro("Moli aria",albero_motore.pistoni[0].aria_cilindro.moli_ossigeno*1000)
		griglia_parametri.scrivi_parametro("Moli scarico",albero_motore.pistoni[0].aria_cilindro.moli_gas_scarico*1000)
		griglia_parametri.scrivi_parametro("Moli carburante",albero_motore.pistoni[0].aria_cilindro.moli_benzina*1000)
		var pressione = (albero_motore.pistoni[0].aria_cilindro.pressione - pressione_atmosferica) * 0.00001
		griglia_parametri.scrivi_parametro("Pressione",pressione)
		griglia_parametri.scrivi_parametro("Volume attuale",albero_motore.pistoni[0].aria_cilindro.volume * 1000)
		griglia_parametri.scrivi_parametro("Temperatura",albero_motore.pistoni[0].aria_cilindro.temperatura)
		griglia_parametri.scrivi_parametro("Validita formula",validita_formula)
		griglia_parametri.scrivi_parametro("Ultimo errore validita",ultimo_errore_validazione_formula)
	for i in range(pistoni_debug.size()):
		if albero_motore.pistoni.size() > i:
			pistoni_debug[i].aggiorna(
				albero_motore.pistoni[i].distanza_pistone_tdc,
				albero_motore.pistoni[i].fase_attuale,
				albero_motore.pistoni[i].rotazione)

func _debug(delta : float):
	pass

var test := 0.0
var contatore := 0

func _process(delta):
	test += delta
	
	if test > 1.0 :
		print("AAAAAAAAAAAAAA: ",contatore)
		contatore = 0
		test = 0.0

var pressione_precedente = 0.0

func calcola_audio(delta : float):
	var pressione = (albero_motore.pistoni[0].aria_cilindro.pressione - pressione_atmosferica)
	pressione = pressione * 0.00001
	var segnale_audio = pressione - pressione_precedente\
		+ albero_motore.pistoni[0].aria_cilindro.volume * 20.0
	pressione_precedente = pressione

	var volume = 86000 * albero_motore.pistoni[0].aria_cilindro.volume * (1.0 + albero_motore.pistoni[0].aria_cilindro.pressione * 0.00001)

	audio.aggiungi_campione_fisico(segnale_audio, delta * compensazione_lentezza_simulazione)
	audio.numero_passaggi_desiderato = volume
