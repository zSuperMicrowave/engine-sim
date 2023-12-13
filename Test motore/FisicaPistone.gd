extends NodoFisicaAudio
class_name FisicaPistone

# Si presuppone che il motore sia posto in verticale.
# Serve un offset base per far partire il pistone in TDC quando è ad angolo 0,
# altrimenti la matematica ci insegna che ad angolo zero un vettore punta verso
# destra. O almeno Questo è ciò che mi ha insegnato il coseno.
# Per andare in TDC partendo dall'albero verso destra, bisogna girare il motore
# di novanta gradi in senso antiorario, nella matematica il senso antiorario è
# un verso di rotazione positivo

const OFFSET_BASE_ROTAZIONE := +PI/2.0
const PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA := 42.698
const COSTANTE_GAS_IDEALE := 8.314

enum {
	ASPIRAZIONE,
	COMPRESSIONE,
	COMBUSTIONE,
	SCARICO
}
var stato_pistone = ASPIRAZIONE

@export var offset_fase := 0.0
@export var area_superficie_pistone := 0.0
@export var altezza_extra_cilindro := 0.01
@export var larghezza_albero := 0.2
@export var lunghezza_biella := 0.5

@export var temperatura_ambiente := 0.0

@export var costrizione_aperta := 0.1
@export var costrizione_chiusa := 0.5

var rotazione_albero := 0.0 # Rotazione dell'albero totale, NON del pistone, impsotata dal motore
var combustione := false

var forza_out := 0.0
var coppia_out := 0.0 # Usata dal motore

# Variabili di lavoro, globali per ogni evenienza ;) e anche 
var rotazione_relativa := OFFSET_BASE_ROTAZIONE + offset_fase # Rotazione dell'albero più gli offset



# SCHIFO SCHIFO ELIMINA ELIMIN
var pressione_scarico := 0.0
var inerzia_scarico := 0.0
@export var costrizione_scarico := 1.0
var pressione_entrata := 0.0
var inerzia_entrata := 0.0
@export var costrizione_entrata := 1.0

@export var peso_inerzia_aria := 1.0
# QUI SU ELIMINA


# La fase attuale posiizona la rotazione nei limiti del ciclo di combustione
# di un motore e applica quello che è l'offset di rotazione di un pistone
# dall'albero motore ma non l'offset base, perché serve a identificare
# le fasi di un motore perciò non và ruotata.
var fase_attuale := offset_fase
var h_biella_attuale := 0.0 # No qui non ho sbatta di fargli fare il calcolo
var vettore_albero := Vector2(larghezza_albero, 0.0)

var temperatura_cilindro := 0.0
var volume_cilindro := 0.1
var pressione_cilindro := 0.0
var numero_moli := 0.0
#var temperatura_motore := 0.0 # Inutilizzato


func _processa_fisica_audio(delta) :
	# Secondo la matematica le rotazioni vanno in senso antioriario, ma il
	# motore girerà in senso orario a causa di vector.orthogonal, che non ho
	# idea se sia giusto o meno usarlo ma non me ne frega un cazzo perché
	# qui il segno dell'operazione non è importante.


	# A inizio ciclo applica tutte le "conseguenze" della rotazione.
	_aggiorna_variabili_lavoro()


	# Calcolo temperatura TEMPORANEO
	if stato_pistone == COMBUSTIONE:
		if !combustione && fase_attuale < TAU+0.5:
			if Input.is_action_pressed("ui_up") :
				temperatura_cilindro = 2500.0
				#forza_out = 8000.0
			elif Input.is_action_pressed("ui_down") :
				temperatura_cilindro = 0.0
				#forza_out = 0.0
			else :
				temperatura_cilindro = 2500.0
				#forza_out = 3000.0
			combustione = true
		temperatura_cilindro = lerp(temperatura_cilindro,temperatura_ambiente,delta*10)
	else :
		temperatura_cilindro = lerp(temperatura_cilindro,temperatura_ambiente,delta*20)
		#forza_out = 0.0
		combustione = false


	volume_cilindro = area_superficie_pistone *\
		( (larghezza_albero + lunghezza_biella + altezza_extra_cilindro)\
		- (h_biella_attuale + vettore_albero.y) )

	if stato_pistone == ASPIRAZIONE:
		var input = Input.get_action_strength("pene_temp")
		var costrizione = costrizione_chiusa * (1.0-input) + costrizione_aperta * input
#			numero_moli = volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA
#		numero_moli = volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA * 0.1
		costrizione_entrata = costrizione
		# TODO: fisica aria migliore
		var volume_in = (volume_cilindro * (2.0 + pressione_entrata)\
			/ (costrizione_entrata*peso_inerzia_aria)) + inerzia_entrata


		pressione_entrata -= volume_in * delta

		inerzia_entrata += pressione_entrata * delta

		numero_moli += volume_in * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA * delta
		if numero_moli > volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA :
			numero_moli = volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA

	pressione_entrata -= pressione_entrata/(costrizione_entrata*peso_inerzia_aria) * delta
	pressione_scarico -= pressione_scarico/(costrizione_scarico*peso_inerzia_aria) * delta


	if stato_pistone == SCARICO:
#		numero_moli = volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA
		# TUTTO FOTTUTO NON SEREVE FA CIFO
		# TODO: fisica aria migliore
		var volume_out = (volume_cilindro * (2.0 + pressione_scarico)\
			/ (costrizione_scarico*peso_inerzia_aria)) + inerzia_scarico


		pressione_scarico += volume_out * delta

		inerzia_scarico += pressione_scarico * delta


		numero_moli -= volume_out * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA * delta
		if numero_moli < volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA :
			numero_moli = volume_cilindro * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA

	# CALCOLO PRESSIONE:
	pressione_cilindro = numero_moli * COSTANTE_GAS_IDEALE * temperatura_cilindro / volume_cilindro # * delta

	#CALOLO FROZA:
	forza_out = pressione_cilindro / area_superficie_pistone * 0.1

	# Trasforma la forza in uscita in coppia
	coppia_out = _converti_forza_coppia()


func _aggiorna_variabili_lavoro() :
	# Aggiorna le variabili che sono conseguenza della rotazione dell'albero

	rotazione_relativa = rotazione_albero + offset_fase + OFFSET_BASE_ROTAZIONE

	# Fase attuale del ciclo di combustione
	if rotazione_albero + offset_fase < 0.0 :
		fase_attuale = - fmod(rotazione_albero + offset_fase, TAU*2)
	else :
		fase_attuale = TAU*2 - fmod(rotazione_albero + offset_fase, TAU*2)

	# Stabilisci lo stato attuale nel ciclo di combustione
	if fase_attuale < PI :
		stato_pistone  = ASPIRAZIONE
	elif fase_attuale < TAU :
		stato_pistone = COMPRESSIONE
	elif fase_attuale < TAU+PI :
		stato_pistone = COMBUSTIONE
	else :
		stato_pistone = SCARICO

	# Altezza della biella:
	# La sua posizione x non serve perché è uguale a quella dell'albero.
	h_biella_attuale = FunzioniMotore.altezza_biella(fase_attuale, larghezza_albero, lunghezza_biella)
	
	# Posizione del perno albero-biella
	vettore_albero = Vector2(
		cos(rotazione_relativa),
		sin(rotazione_relativa)
		) * larghezza_albero


func _converti_forza_coppia() :
	# Restituisce la coppia a partire dalla forza
	# Per farlo bisogna prima prendere la forza trasmessa alla biella dal
	# pistone e poi vedere quanta di questa forza viene trasmessa
	# all'albero motore
	var x_albero = cos(rotazione_relativa) * larghezza_albero
	
	# Calcola la forza trasmessa dal pistone alla biella.
	# La seguente formula è una semplificazione di:
	# calcola il vettore della biella, normalizzalo, imposta la forza come
	# vettore verso il basso, calcola il prodotto scalare tra vettore biella e
	# vettore forza.
	# Invece di fare questo casino possiamo moltiplicare direttamente le y dei
	# vettori perché la x del vettore forza sarà sempre zero, e quindi di fatto
	# moltiplicare la forza per l'altezza della biella normalizzata, quindi
	# per l'altezza della biella divisa dalla lunghezza della stessa
	var forza_biella = forza_out * h_biella_attuale / lunghezza_biella

	# Il risultato del prodotto scalare è, per sua definizione, uno scalare
	# tuttavia a noi serve un vettore per poter calcolare la forza trasmessa
	# poi all'albero. Qui non si possono fare semplificazioni, bisogna fare
	# un prodotto scalare diretto, perciò moltiplichiamo il modulo del
	# vettore biella per la forza trasmessa per avere il vettore forza biella.
	var vettore_forza_biella = forza_biella *\
		Vector2(x_albero, -h_biella_attuale).normalized()
	
	# Per avere la coppia risultante basta fare il prodotto scalare tra forza
	# trasmessa dalla biella e la perpendicolare del vettore leva dell'albero
	return -vettore_albero.normalized().orthogonal().dot(vettore_forza_biella) * larghezza_albero


func _physics_process(delta):
	#print(pressione_scarico)
	if combustione :
		$cazzillo.scale = Vector2.ONE * 0.4
	else :
		$cazzillo.scale = Vector2.ONE * 0.15
	#print(volume_cilindro)
#	grafico1.invia_dato(numero_moli - 0.01)
#	grafico2.invia_dato(volume_cilindro)
	
	$cazzillo.position = Vector2(vettore_albero.x,-vettore_albero.y) * 1000 + Vector2(800,300)
