extends ComponenteAudio
class_name TuboAudio

var direzione_positiva_passaggi : Array[float]
var direzione_negativa_passaggi : Array[float]
var i_buffer_positivo := 0
var i_buffer_negativo := 0

@export_range(0.01,2.0) var moltiplicatore_input_output := 1.0

@export_category("ComponenteAudio")
@export var campionatore : CampionatorePistone

@export_group("Impostazioni Tubo")

@export_subgroup("Riverbero primario")
@export_range(2,4000) var dimensione_coda := 5
@export var tubo_chiuso := true
@export var coda_modulata := false

@export_subgroup("Attenuazione")
@export var moltiplicatore_energia_rimbalzo := 0.8
@export var attenuazione_suono := 1.0

@export_subgroup("Ovattamento")
@export_range(0.0,1.0) var ovattamento_suono := 0.1
@export var campioni_ovattamento_massimi := 30

@export_group("Debug e Test")
@export_enum("NON FARE NULLA","TRONCA","SCALA","ESTENDI")\
	var metodo_restringimento_buffer := 1
@export_enum("NON FARE NULLA","TRONCA","SCALA","ESTENDI","SCALA PROPORZIONALMENTE","BLOCCA")\
	var metodo_allargamento_buffer := 1
@export_enum("CICLA","SCALA")\
	var riposiziona_restringimento_buffer := 0
@export_enum("CICLA","SCALA")\
	var riposiziona_allargamento_buffer := 0


func _ready():
	direzione_positiva_passaggi.resize(dimensione_coda)
	direzione_negativa_passaggi.resize(dimensione_coda)


func ottieni_campione() -> float:
	if coda_modulata :
		_aggiorna_dimensione_coda()

	var delta = 1.0 / InfoAudio.frequenza_campionamento_hz
	var attenuazione = 1.0/(1.0+attenuazione_suono*dimensione_coda*0.0001)
	var ampiezza_ovattamento : int = ovattamento_suono *\
		clamp(dimensione_coda,0,campioni_ovattamento_massimi-1) + 1


	var input : float =\
		campionatore.ottieni_campione() * moltiplicatore_input_output

	# AGGIORNA POSIZIONI DEI PUNTATORI
	
	i_buffer_positivo += 1
	if i_buffer_positivo >= dimensione_coda:
		i_buffer_positivo = 0
	
	i_buffer_negativo -= 1
	if i_buffer_negativo <= 0:
		i_buffer_negativo = dimensione_coda - 1


	# ATTENUAZIONE
	direzione_negativa_passaggi[i_buffer_negativo] *= attenuazione
	direzione_positiva_passaggi[i_buffer_positivo] *= attenuazione


	# SCAMBIO
	var temp_neg = direzione_negativa_passaggi[i_buffer_negativo]
	
	direzione_negativa_passaggi[i_buffer_negativo] =\
		 direzione_positiva_passaggi[i_buffer_positivo] * moltiplicatore_energia_rimbalzo
	if tubo_chiuso : direzione_negativa_passaggi[i_buffer_negativo] *= -1
	
	direzione_positiva_passaggi[i_buffer_positivo] =\
		 temp_neg * moltiplicatore_energia_rimbalzo


	# INPUT
	direzione_positiva_passaggi[i_buffer_positivo] += input


	# OUTPUT
	var risultato = 0.0
	for i in range(ampiezza_ovattamento):
		var sex = fmod(i_buffer_positivo + i, dimensione_coda)
		risultato += direzione_positiva_passaggi[sex]
	risultato /= ampiezza_ovattamento
	risultato *= moltiplicatore_input_output

	return risultato


func _estendi_buffer(nuova_dimensione:int) -> void :
	var vecchio_buffer_positivo = direzione_positiva_passaggi.duplicate()
	var vecchio_buffer_negativo = direzione_negativa_passaggi.duplicate()
	direzione_positiva_passaggi.resize(nuova_dimensione)
	direzione_negativa_passaggi.resize(nuova_dimensione)

	var delta := 0
	var direzione_positiva_output = true
	var j := 0
	var direzione_positiva_input = true
	for i in range(nuova_dimensione*2) :
		j = i
		if i >= nuova_dimensione :
			direzione_positiva_output = !direzione_positiva_output
			delta += nuova_dimensione
		if j >= vecchio_buffer_positivo.size() :
			direzione_positiva_input = !direzione_positiva_input
			j = 0.0
		
		var val = 0.0
		
		if direzione_positiva_input :
			val = vecchio_buffer_positivo[j]
		else :
			val = vecchio_buffer_negativo[j]
		
		if direzione_positiva_output :
			direzione_positiva_passaggi[i - delta] = val
		else :
			direzione_negativa_passaggi[i - delta] = val


func _scala_proporzionalmente_array(array:Array, nuova_dimensione:int) -> void:
	if array.size() == nuova_dimensione :
		return
	if array.size() > nuova_dimensione :
		printerr("Non si può scalare proporzionalmente a diminuire")
		_scala_array(array,nuova_dimensione)
		return

	var vecchio_array = array.duplicate()
	array.resize(nuova_dimensione)
	
	var rapporto :=\
		vecchio_array.size() as float / nuova_dimensione as float
		
	var j := 0
	var contatore := 0.0
	for i in range(array.size()):
		if j < vecchio_array.size()-1 :
			array[i] = vecchio_array[j] * (1.0 - contatore)\
				+ vecchio_array[j+1] * contatore
		else :
			array[i] = vecchio_array[j]
		
		contatore += rapporto
		while contatore >= 1.0 :
			contatore -= 1.0
			j += 1

func _scala_array(array:Array, nuova_dimensione:int) -> void:
	if array.size() == nuova_dimensione :
		return

	var vecchio_array = array.duplicate()
	array.resize(nuova_dimensione)
	
	var rapporto :=\
		vecchio_array.size() as float / nuova_dimensione as float
		
	var j := 0
	var contatore := 0.0
	for i in range(array.size()):
		array[i] = vecchio_array[j]
		
		contatore += rapporto
		while contatore >= 1.0 :
			contatore -= 1.0
			j += 1



func _aggiorna_dimensione_coda():
	# Se non ci sono differenze nella coda, concludi la chiamata
	if campionatore.ottieni_riverbero() as int == dimensione_coda : return

	var dimensione_coda_desiderata := campionatore.ottieni_riverbero() as int
	if dimensione_coda_desiderata < 2 :
		dimensione_coda_desiderata = 200
		printerr("Richiesta dimensione coda minore di zero")
	var rapporto = dimensione_coda_desiderata as float / dimensione_coda as float

	if rapporto > 1.0 :
		match metodo_allargamento_buffer :
			1:
				direzione_positiva_passaggi.resize(dimensione_coda_desiderata)
				direzione_negativa_passaggi.resize(dimensione_coda_desiderata)
			2:
				_scala_array(direzione_positiva_passaggi, dimensione_coda_desiderata)
				_scala_array(direzione_negativa_passaggi, dimensione_coda_desiderata)
			3:
				_estendi_buffer(dimensione_coda_desiderata)
			4:
				_scala_proporzionalmente_array(
					direzione_positiva_passaggi, dimensione_coda_desiderata)
				_scala_proporzionalmente_array(
					direzione_negativa_passaggi, dimensione_coda_desiderata)
			5:
				direzione_positiva_passaggi.resize(dimensione_coda_desiderata)
				direzione_negativa_passaggi.resize(dimensione_coda_desiderata)
				var i = dimensione_coda
				var val_p = direzione_positiva_passaggi[dimensione_coda-1]
				var val_n = direzione_negativa_passaggi[dimensione_coda-1]
				while i < dimensione_coda_desiderata:
					direzione_positiva_passaggi[i] = val_p
					direzione_negativa_passaggi[i] = val_n
					i+=1
		
		match riposiziona_allargamento_buffer :
			0:
				i_buffer_negativo %= dimensione_coda_desiderata
				i_buffer_positivo %= dimensione_coda_desiderata
			1:
				i_buffer_negativo *= rapporto
				i_buffer_positivo *= rapporto
	else :
		match metodo_restringimento_buffer :
			1:
				direzione_positiva_passaggi.resize(dimensione_coda_desiderata)
				direzione_negativa_passaggi.resize(dimensione_coda_desiderata)
			2:
				_scala_array(direzione_positiva_passaggi, dimensione_coda_desiderata)
				_scala_array(direzione_negativa_passaggi, dimensione_coda_desiderata)
			3:
				_estendi_buffer(dimensione_coda_desiderata)
		
		match riposiziona_restringimento_buffer :
			0:
				i_buffer_negativo %= dimensione_coda_desiderata
				i_buffer_positivo %= dimensione_coda_desiderata
			1:
				i_buffer_negativo *= rapporto
				i_buffer_positivo *= rapporto

	dimensione_coda = dimensione_coda_desiderata
