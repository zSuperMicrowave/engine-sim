extends ComponenteAudio
class_name CilindroAudio

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]
var i_buffer_positivo := 0
var i_buffer_negativo := 0
var resto_puntatori := 0.0

@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_category("ComponenteAudio")
@export var componente_precedente : ComponenteAudio

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var dimensione_coda := 5
var velocita_attraversamento := 1.0
var velocita_attraversamento_int := 1
@export var tubo_chiuso := true

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_group("Debug e Test")
@export var silenzia_errori := false


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
	i_buffer_positivo = 0
	i_buffer_negativo = 0
	velocita_attraversamento = 1.0
	velocita_attraversamento_int = 1
	for i in range(direzione_positiva_passaggi.size()):
		direzione_positiva_passaggi[i] = 0.0
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	avanza_puntatori()
	input_valori(1.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	avanza_puntatori()
	input_valori(2.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	print("adesso metto la velocità a 1.25x")
	velocita_attraversamento = 1.25
	velocita_attraversamento_int = 1
	avanza_puntatori()
	input_valori(3.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	avanza_puntatori()
	input_valori(4.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	avanza_puntatori()
	input_valori(5.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	avanza_puntatori()
	input_valori(6.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)
	avanza_puntatori()
	input_valori(7.0)
	print(direzione_positiva_passaggi)
	print("pos:", i_buffer_positivo, "neg:", i_buffer_negativo," resto:",resto_puntatori)


func _enter_tree():
	direzione_positiva_passaggi.resize(dimensione_coda)
	direzione_negativa_passaggi.resize(dimensione_coda)


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
	var risultato = direzione_positiva_passaggi[i_buffer_positivo]
	risultato *= moltiplicatore_input_output

	return risultato


func avanza_puntatori():
	var vel : int = velocita_attraversamento_int
	resto_puntatori += velocita_attraversamento - velocita_attraversamento_int
	if resto_puntatori >= 1.0 :
		resto_puntatori = 0.0
		vel += 1

	i_buffer_positivo += vel
	if i_buffer_positivo >= dimensione_coda:
		i_buffer_positivo = 0
	
	i_buffer_negativo -= vel
	if i_buffer_negativo <= 0:
		i_buffer_negativo = dimensione_coda - 1


func applica_attenuazione(attenuazione : float):
	for i in range(velocita_attraversamento_int+1) :
		var nuovo_i_negativo = fmod(i_buffer_negativo + i,dimensione_coda)
		var nuovo_i_positivo = dimensione_coda - 1 - nuovo_i_negativo
		
		
		if i == velocita_attraversamento_int :
			direzione_negativa_passaggi[nuovo_i_negativo] *=\
				lerpf(attenuazione,1.0,resto_puntatori)
			direzione_positiva_passaggi[nuovo_i_positivo] *=\
				lerpf(attenuazione,1.0,resto_puntatori)
		else :
			direzione_negativa_passaggi[nuovo_i_negativo] *= attenuazione
			direzione_positiva_passaggi[nuovo_i_positivo] *= attenuazione


func scambia_valori():
	for i in range(velocita_attraversamento_int+1) :
		var nuovo_i_negativo = fmod(i_buffer_negativo + i,dimensione_coda)
		var nuovo_i_positivo = dimensione_coda - 1 - nuovo_i_negativo
		
		
		if i == velocita_attraversamento_int :
			var temp_neg = direzione_negativa_passaggi[nuovo_i_negativo]
			
			direzione_negativa_passaggi[nuovo_i_negativo] = lerpf(
				direzione_negativa_passaggi[nuovo_i_negativo],
				direzione_positiva_passaggi[nuovo_i_positivo] * moltiplicatore_energia_rimbalzo,
				resto_puntatori)
			
			if tubo_chiuso :
				direzione_negativa_passaggi[nuovo_i_negativo] = lerpf(
					direzione_negativa_passaggi[nuovo_i_negativo],
					direzione_negativa_passaggi[nuovo_i_negativo] * -1,
					resto_puntatori)
			
			direzione_positiva_passaggi[nuovo_i_positivo] = lerpf(
				direzione_positiva_passaggi[nuovo_i_positivo],
				temp_neg * moltiplicatore_energia_rimbalzo,
				resto_puntatori)
		else :
			var temp_neg = direzione_negativa_passaggi[nuovo_i_negativo]
			
			direzione_negativa_passaggi[nuovo_i_negativo] =\
				 direzione_positiva_passaggi[nuovo_i_positivo] * moltiplicatore_energia_rimbalzo
			
			if tubo_chiuso : direzione_negativa_passaggi[nuovo_i_negativo] *= -1
			
			direzione_positiva_passaggi[nuovo_i_positivo] =\
				 temp_neg * moltiplicatore_energia_rimbalzo

var ultimo_resto := 0.0
func input_valori(input : float):
	var ultimo = 0.0
	var extra := 0
	if not is_equal_approx(velocita_attraversamento,velocita_attraversamento_int) :
		extra = 1
	
	for i in range(velocita_attraversamento_int+extra) :
		var nuovo_i_negativo = fmod(i_buffer_negativo + i,dimensione_coda)
		var nuovo_i_positivo = dimensione_coda - 1 - nuovo_i_negativo
		
		if is_zero_approx(resto_puntatori) :
			if i != 0 :
				direzione_positiva_passaggi[nuovo_i_positivo] += input
			else :
				direzione_positiva_passaggi[nuovo_i_positivo] += input * resto_puntatori
		else :
			if i == velocita_attraversamento_int :
				direzione_positiva_passaggi[nuovo_i_positivo] += input * (1.0-ultimo_resto)
			else :
				direzione_positiva_passaggi[nuovo_i_positivo] += input
			
			ultimo_resto = resto_puntatori


func aggiorna_riverbero():
	var nuovo_riverbero : int = componente_precedente.ottieni_riverbero()

	if nuovo_riverbero > dimensione_coda :
		dimensione_coda = nuovo_riverbero
		direzione_positiva_passaggi.resize(dimensione_coda)
		direzione_negativa_passaggi.resize(dimensione_coda)
		i_buffer_negativo = fmod(i_buffer_negativo,dimensione_coda)
		i_buffer_positivo = fmod(i_buffer_positivo,dimensione_coda)

	velocita_attraversamento = dimensione_coda as float / nuovo_riverbero as float
	velocita_attraversamento_int = floori(velocita_attraversamento)
