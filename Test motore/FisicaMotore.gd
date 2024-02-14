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
@export var campionatore_pistone : Array[CampionatorePistone]


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
var ultimo_delta := 1.0


func _calcola_audio(delta : float):
	ultimo_delta = delta
	ssss += delta
	var pressione_totale := 0.0
	for pistone in pistoni:
		pressione_totale += pistone.pressione_cilindro
	
	grafico_pressione.invia_dato(pistoni[0].numero_moli)
	
	
	for i in range(campionatore_pistone.size()) :
		if pistoni.size() <= i :
			break
		campionatore_pistone[i].invia_campione(pistoni[i].pressione_cilindro, pistoni[i].temperatura_cilindro, delta)
		campionatore_pistone[i].imposta_riverbero_retrocompatibile(pistoni[i].volume_cilindro, pistoni[i].pressione_cilindro)


func _physics_process(delta):
	t+= delta
	if t > 1.0:
		t = 0.0
		print("ae ",cont)
		cont = 0
	#print(cos(rotazione))
	grafico.invia_dato(abs(velocita_angolare))
	#print(velocita_angolare)
