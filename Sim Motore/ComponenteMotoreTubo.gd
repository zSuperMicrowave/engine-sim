extends Node
class_name ComponenteMotoreTubo

const VELOCITA_SUONO_CMS := 43400.0

# |--------------
# | Simulazione risonanza suono in un tubo
# |--------------
# | Il suono si propaga lungo il tubo e quando raggiunge la fine si rilfette
# | e viene attenuato, poi quando raggiunge l'inizio si riflette di nuovo.
# | Nell'implementazione qui di sotto, il suono è un float che percorre un
# | array. In un implementazione più vicina alla realtà, possiamo immaginare
# | che tutti i float nell'array si spostino verso destra, e che quando
# | raggiungono la fine, vengano riflessi e spostati pian piano verso sinistra
# | in un secondo array di ritorno, in cui poi vengono ririflessi nel primo
# | con un po' di attenuazione.
# | Per ridurre il peso di questa implementazione, che costringerebbe a
# | Manipolare tutto l'array, nel codice di sotto si immagina che siano le
# | pareti a spostarsi e non il suono, pertanto i float conservati verranno
# | ad ogni iterazione scambiati tra i due array, poi verrà aggiunto l'input
# | all'array che scorre in avanti e campionato il suono nel medesimo
# | puntatore.
# | Infine, per "ovattare" il suono, in uscita questo viene campionato
# | sia dal puntatore che dai suoni lasciati in precedenza.
# |--------------

@export var lunghezza_tubo_cm := 100 :
	set(valore):
		richiesta_cambio_dimensioni_array = true
		numero_passaggi_desiderato = lunghezza_tubo_cm * larghezza_tubo_cm * Unita.cm2
@export var larghezza_tubo_cm := 100 :
	set(valore):
		richiesta_cambio_dimensioni_array = true
		numero_passaggi_desiderato = lunghezza_tubo_cm * larghezza_tubo_cm * Unita.cm2

@onready var numero_passaggi_desiderato : int = lunghezza_tubo_cm * larghezza_tubo_cm * Unita.cm2
@onready var numero_passaggi : int = numero_passaggi_desiderato

var richiesta_cambio_dimensioni_array := false

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]

var i_buffer_positivo := 0
var i_buffer_negativo := 0

@export var moltiplicatore_energia_rimbalzo := 0.8
@export_range(0.0,1.0) var dispersione_campionamento_suono := 0.1

@export var attenuazione_suono := 1.0
var attenuazione_effettiva := 0.0

@export var campioni_dispersione_output_massimi := 30
var ampiezza_dispersione_effettiva := 1

var input := 0.0
var output := 0.0



func _ricalcola_dimensioni_array():
	numero_passaggi = numero_passaggi_desiderato
	direzione_positiva_passaggi.resize(numero_passaggi)
	direzione_negativa_passaggi.resize(numero_passaggi)
	i_buffer_negativo = i_buffer_negativo % numero_passaggi
	i_buffer_positivo = i_buffer_positivo % numero_passaggi
	
	
	richiesta_cambio_dimensioni_array = false


func _ready() -> void:
	_ricalcola_dimensioni_array()
	_elabora()


func _elabora():
	if richiesta_cambio_dimensioni_array:
		_ricalcola_dimensioni_array()

	# AGGIORNA POSIZIONI DEI PUNTATORI
	
	i_buffer_positivo += 1
	if i_buffer_positivo >= numero_passaggi:
		i_buffer_positivo = 0
	
	i_buffer_negativo -= 1
	if i_buffer_negativo <= 0:
		i_buffer_negativo = numero_passaggi - 1


	# ATTENUAZIONE
	direzione_negativa_passaggi[i_buffer_negativo] *= attenuazione_effettiva
	direzione_positiva_passaggi[i_buffer_positivo] *= attenuazione_effettiva


	# SCAMBIO
	var temp_neg = direzione_negativa_passaggi[i_buffer_negativo]
	
	direzione_negativa_passaggi[i_buffer_negativo] =\
		 direzione_positiva_passaggi[i_buffer_positivo] * moltiplicatore_energia_rimbalzo
	
	direzione_positiva_passaggi[i_buffer_positivo] =\
		 temp_neg * moltiplicatore_energia_rimbalzo


	# INPUT
	direzione_positiva_passaggi[i_buffer_positivo] += input


	# OUTPUT
	var risultato = 0.0
	for i in range(ampiezza_dispersione_effettiva):
		var sex = fmod(i_buffer_positivo + i, numero_passaggi)
		risultato += direzione_positiva_passaggi[sex]
	risultato /= ampiezza_dispersione_effettiva
	
	output = risultato


func _physics_process(delta: float) -> void:
	# Aggiorna variabili che vengono usate bla bla bla
	
	attenuazione_effettiva = 1.0/(1.0+attenuazione_suono*numero_passaggi*0.0001)
	
	ampiezza_dispersione_effettiva = dispersione_campionamento_suono *\
		clamp(numero_passaggi,0,campioni_dispersione_output_massimi-1) + 1
