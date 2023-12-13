@icon("res://Test motore 2/Componenti Simulazione Fisica/icona-motore.png")
extends Node
class_name ComponenteMotore


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
@export var audio : RisonanzaBufferizzataAudioPlayerVecchio


var dbg_len := 0.0
var elab_ecu := 0.0

func _elabora_fisica_motore(delta: float) -> void :
	albero_motore.elabora(self, delta)

	contatore += 1

	elab_ecu += delta
	if elab_ecu >= 1.0 / ecu.velocita_aggiornamento_ecu_hz:
		ecu.elabora(self)
		elab_ecu = 0.0

	if dbg_len >=  1.0 / velocita_debug_lento_hz:
		call_deferred("_debug_lento")
		dbg_len = 0.0
	dbg_len += delta
	call_deferred("_debug",delta)
	audio.aggiungi_campione_fisico(0.0001 * albero_motore.pistoni[0].pressione_cilindro, delta)
	audio.numero_passaggi_desiderato = 86800 * albero_motore.pistoni[0].volume_attuale * 1

func _debug_lento():
	if griglia_parametri :
		griglia_parametri.scrivi_parametro("RPM", albero_motore.velocita_angolare / Unita.rpm)
		griglia_parametri.scrivi_parametro("RPM motorino avviatore"
			, albero_motore.motorino_avviamento.velocita_attuale / Unita.rpm)
		griglia_parametri.scrivi_parametro("Moli aria",albero_motore.pistoni[0].numero_moli_aria_attuale*1000)
		griglia_parametri.scrivi_parametro("Moli scarico",albero_motore.pistoni[0].numero_moli_scarico_attuale*1000)
		griglia_parametri.scrivi_parametro("Moli carburante",albero_motore.pistoni[0].numero_moli_carburante_attuale*1000)
		griglia_parametri.scrivi_parametro("Pressione",albero_motore.pistoni[0].pressione_cilindro)
		griglia_parametri.scrivi_parametro("Volume attuale",albero_motore.pistoni[0].volume_attuale * 1000)
	for i in range(pistoni_debug.size()):
		if albero_motore.pistoni.size() > i:
			pistoni_debug[i].aggiorna(albero_motore.pistoni[i].distanza_pistone_tdc,albero_motore.pistoni[i].fase_attuale)

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
