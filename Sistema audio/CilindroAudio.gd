extends ComponenteAudio
class_name CilindroAudio

var coda_passaggi : Array[float]
var puntatore_coda_precedente : float
var puntatore_coda : float

@export_range(0.1,4.0) var qualita := 1.0
@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_category("ComponenteAudio")
@export var componente_precedente : ComponenteAudio

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var dimensione_coda := 5
var velocita_attraversamento := 1.0
#@export var tubo_chiuso := true

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_group("Debug e Test")
@export var silenzia_errori := false

var ttt := 0.0
func _process(delta):
	ttt += delta
	if ttt >= 5.0 && ttt < 5.1 : 
		max_att = 0.0
		print(dimensione_coda)

func _ready():
	#Squenza di test: eliminami quando finisci
	#Log:
	# Ok ho testato l'avanzamento dei puntatori e funziona correttamente, almeno
	# fa quel che ho progettato che dovesse fare, no non so poi se effettivamente
	# il progetto è giusto... Vabbè funziona come da progetto
	# Però devo provare l'input dei valori, perché funziona in maniera un po'
	# Strana, è da vedere e capire bene... Forse è sbagliato l'oridne di inserimento
	# dei numeri... mh sì giusto! vabbè praticamente una volta salta 2 valori
	# e una volta ne salta 3, quindi devi coordinarti corretamentjo jgnjodg
	# sbatta, sbatta, ti attacchi ahaha
	puntatore_coda = 0
	velocita_attraversamento = 1.25
	for i in range(coda_passaggi.size()):
		coda_passaggi[i] = 0.0
	print("puntatore:", puntatore_coda)
	input_valori(1.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	input_valori(2.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	velocita_attraversamento = 1.25
	print("adesso metto la velocità a ",velocita_attraversamento,"x")
	input_valori(3.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	input_valori(2.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	input_valori(1.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	input_valori(0.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	input_valori(-7.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)
	input_valori(7.0)
	avanza_puntatori()
	print(coda_passaggi)
	print("puntatore:", puntatore_coda)


func _enter_tree():
	coda_passaggi.resize(dimensione_coda*2)


func ottieni_campione() -> float:
	#return 0.0
	aggiorna_riverbero()

	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
	var attenuazione = 1.0/(1.0+attenuazione_suono*0.001)


	var input : float =\
		componente_precedente.ottieni_campione() * moltiplicatore_input_output

	# AGGIORNA POSIZIONI DEI PUNTATORI
	avanza_puntatori() # L'ho testato, questo funziona


	# ATTENUAZIONE
	applica_attenuazione(attenuazione)


	# SCAMBIO
	scambia_valori()

	# INPUT
	input_valori(input)


	# OUTPUT
	var risultato = coda_passaggi[roundi(puntatore_coda)]
	risultato *= moltiplicatore_input_output

	return risultato


func avanza_puntatori():
	puntatore_coda = fmod(puntatore_coda+velocita_attraversamento, dimensione_coda)


func applica_attenuazione(attenuazione : float):
	for i in range(floori(puntatore_coda-velocita_attraversamento), ceili(puntatore_coda)) :
		var t : float = 1 - min((puntatore_coda - i) / velocita_attraversamento, 1.0)
		i = fposmod(i, dimensione_coda) as int
		
		var att = lerpf(1.0,attenuazione,t)
		
		coda_passaggi[dimensione_coda + i] *= att
		coda_passaggi[i] *= att
	
	for i in range(ceili(puntatore_coda), ceili(puntatore_coda + velocita_attraversamento)) :
		var t : float = min((i - puntatore_coda) / velocita_attraversamento, 1.0)
		i = fposmod(i, dimensione_coda) as int
		
		var att = lerpf(1.0,attenuazione,t)
		
		coda_passaggi[dimensione_coda + i] *= att
		coda_passaggi[i] *= att


func scambia_valori():
	for i in range(floori(puntatore_coda-velocita_attraversamento), ceili(puntatore_coda)) :
		var t : float = 1 - min((puntatore_coda - i) / velocita_attraversamento, 1.0)
		i = fposmod(i, dimensione_coda) as int
		
		# Effettua scambio
		var temp = coda_passaggi[dimensione_coda + i]
		coda_passaggi[dimensione_coda + i] *= (1-t)
		coda_passaggi[dimensione_coda + i] += coda_passaggi[i] * t * moltiplicatore_energia_rimbalzo
		
		coda_passaggi[i] *= (1-t)
		coda_passaggi[i] += temp * t * moltiplicatore_energia_rimbalzo
	
	for i in range(ceili(puntatore_coda), ceili(puntatore_coda + velocita_attraversamento)) :
		var t : float = min((i - puntatore_coda) / velocita_attraversamento, 1.0)
		i = fposmod(i, dimensione_coda) as int
		
		# Effettua scambio
		var temp = coda_passaggi[dimensione_coda + i]
		coda_passaggi[dimensione_coda + i] *= (1-t)
		coda_passaggi[dimensione_coda + i] += coda_passaggi[i] * t * moltiplicatore_energia_rimbalzo
		
		coda_passaggi[i] *= (1-t)
		coda_passaggi[i] += temp * t * moltiplicatore_energia_rimbalzo

var ultimo_input := 0.0
func input_valori(input : float):
	var delta_input = input - ultimo_input
	
	for i in range(floori(puntatore_coda-velocita_attraversamento), ceili(puntatore_coda)) :
		var t : float = 1 - min((puntatore_coda - i) / velocita_attraversamento, 1.0)
		var da_iserire = delta_input * t
		
		i = fposmod(i, dimensione_coda) as int
		coda_passaggi[i] += da_iserire
	
	for i in range(ceili(puntatore_coda), ceili(puntatore_coda + velocita_attraversamento)) :
		i = fposmod(i, dimensione_coda) as int
		coda_passaggi[i] += input
	
	ultimo_input = input


var min_att = 13980513095.0
var max_att = 0.0

func aggiorna_riverbero():
	var nuovo_riverbero : int = componente_precedente.ottieni_riverbero()

	nuovo_riverbero = clamp(nuovo_riverbero*qualita,10,2000)

	if nuovo_riverbero > dimensione_coda :
		dimensione_coda = nuovo_riverbero
		coda_passaggi.resize(dimensione_coda*2)
		puntatore_coda = fmod(puntatore_coda,dimensione_coda)

	velocita_attraversamento = dimensione_coda*qualita as float / nuovo_riverbero as float

	if min_att > velocita_attraversamento :
		min_att = velocita_attraversamento
		print("MIN ATT = ",velocita_attraversamento)
	if max_att < velocita_attraversamento :
		max_att = velocita_attraversamento
		print("MAX ATT = ",velocita_attraversamento)
