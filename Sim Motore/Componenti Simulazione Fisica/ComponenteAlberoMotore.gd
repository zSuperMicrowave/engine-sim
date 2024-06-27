extends Resource
class_name ComponenteAlberoMotore

@export_category("Componenti")
@export var pistoni : Array[ComponentePistone]
@export var motorino_avviamento : ComponenteMotorinoAvviamento

var rotazione := 0.0
var velocita_angolare := 0.0
var coppia_totale := 0.0



func _elabora_componenti(motore : ComponenteMotore, delta : float):
	motorino_avviamento.elabora(motore, delta)
	var threads : Array[Thread]
	for pistone in pistoni:
		var t = Thread.new()
		t.start(Callable(pistone,"elabora").bind(motore,delta))
		threads.append(t)
		#pistone.elabora(motore, delta)
	
	for t in threads:
		t.wait_to_finish()


func _ottieni_forze(motore : ComponenteMotore):
	var coppia_avviamento = motorino_avviamento.ottieni_coppia()
	var coppia_attrito = -motore.coefficiente_attrito_meccanico_totale * velocita_angolare
	var coppia_pistoni = 0.0
	for pistone in pistoni:
		coppia_pistoni += pistone.ottieni_coppia(motore)

	coppia_totale = coppia_avviamento + coppia_attrito + coppia_pistoni
	coppia_totale /= motore.volano.inerzia


func _aggiorna_parametri():
	motorino_avviamento.imposta_parametri(velocita_angolare)
	for pistone in pistoni:
		pistone.imposta_parametri(rotazione)



func elabora(motore : ComponenteMotore, delta : float):
	# FLUSSO DI ELABORAZIONE PRINCIPALE:
	# -> Avvisa ai componenti figli di elaborare i loro dati
	# -> Ottieni i dati elaborati dai figli
	# -> Usa i dati per calcolare velocita e rotazione
	# -> Aggiorna tutti i componenti figli nei cambiamenti di velocita e rotazione
	
	# Elabora componenti
	_elabora_componenti(motore, delta)

	# Ottieni forze coinvolte
	_ottieni_forze(motore)

	# Applica rotazione
	velocita_angolare += coppia_totale * delta
	rotazione += velocita_angolare * delta

	# Aggiorna parametri componenti
	_aggiorna_parametri()
