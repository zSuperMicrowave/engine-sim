extends NodoFisicaAudio
class_name FisicaMotore

# Si presuppone che il motore sia posto in verticale.


@export_category("Pezzi Motore")
@export var pistoni : Array[FisicaPistone]


@export_category("Proprieta Volano")
# Variabili utili al calcolo dell'inerzia
var inerzia := 1.0 # kg/m^2
@export var raggio := 1.0: # m
	set(valore):
		raggio = valore
		inerzia = 0.5 * massa * pow(raggio,2)
@export var massa := 1.0: # kg
	set(valore):
		massa = valore
		inerzia = 0.5 * massa * pow(raggio,2)


@export_category("Proprieta Motore")
@export var coefficiente_attrito := 0.0

var velocita_angolare := 0.0 # rad/s
var rotazione := 0.0 # radianti


@export_category("Visualizzazione")
#Grafici e cazzi
@export var grafico : Grafico2D
@export var grafico_pressione : Grafico2D
@export var buffer_audio : BufferFisicaAudio
@export var buffer_risonanza : RisonanzaBufferizzataAudioPlayer
@export var buffer_risonanza_vecchio : RisonanzaBufferizzataAudioPlayerVecchio


var t = 0.0
var cont = 0

func _processa_fisica_audio(delta) :
	cont +=1
	
	# Coppia motore
	var coppia_motore = _calcola_coppia_motore()
	if Input.is_action_pressed("ui_accept") : coppia_motore -= 5000.0
	
	# Coppia attrito
	var coppia_attrito = _calcola_forze_attrito()

	# Somma delle coppie
	var coppia_somma = coppia_motore + coppia_attrito
	
	# Applica le forze alla velocita
	velocita_angolare += (coppia_somma/inerzia) * delta
	# Applica la velocita alla rotazione
	rotazione += velocita_angolare * delta * 0.1
	
	
	# Aggiorna le variabili dei componenti del motore
	for pistone in pistoni :
		pistone.rotazione_albero = rotazione
	
	_calcola_audio(delta)


func _calcola_forze_attrito():
	return -coefficiente_attrito * velocita_angolare


func _calcola_coppia_motore() :
	var coppia_totale = 0.0
	
	
	for pistone in pistoni :
		# TODO aggiungere calcoli di direzione e cazzi
		coppia_totale += pistone.coppia_out
	
	return coppia_totale

var ssss = 0.0

func _calcola_audio(delta : float):
	ssss += delta
	var pressione_totale := 0.0
	for pistone in pistoni:
		pressione_totale += pistone.pressione_cilindro
	
	grafico_pressione.invia_dato(pistoni[0].numero_moli)
	
	if buffer_audio :
		buffer_audio.call_deferred("aggiungi_campione_fisico",(pressione_totale * 0.0000001) ,delta)
	if buffer_risonanza :
		buffer_risonanza.aggiungi_campione_fisico(
			(pressione_totale * 0.0000001)\
			+ pistoni[0].volume_cilindro * 100,delta)
		buffer_risonanza.numero_passaggi_desiderato = 86800 * pistoni[0].volume_cilindro
	if buffer_risonanza_vecchio :
		buffer_risonanza_vecchio.aggiungi_campione_fisico(
			pressione_totale * 0.0000001,delta)
		buffer_risonanza_vecchio.numero_passaggi_desiderato = 86800 * pistoni[0].volume_cilindro * 1
		#buffer_risonanza_vecchio.numero_passaggi_desiderato = 88 + 80 * sin(ssss)

func _physics_process(delta):
	t+= delta
	if t > 1.0:
		t = 0.0
		print("ae ",cont)
		cont = 0
	#print(cos(rotazione))
	grafico.invia_dato(abs(velocita_angolare))
	#print(velocita_angolare)
