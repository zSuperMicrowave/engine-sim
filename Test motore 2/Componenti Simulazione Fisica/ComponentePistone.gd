extends Resource
class_name ComponentePistone

const OFFSET_BASE_ROTAZIONE := -PI/2.0
const PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA := 42.698
const COSTANTE_GAS_IDEALE := 8.314
const QNT_ARIA_REAZIONE_CARBURANTE := 12.5
const GRADI_PER_MOLE_REAZIONE := 4000.0

enum {
	ASPIRAZIONE,
	COMPRESSIONE,
	COMBUSTIONE,
	ESPULSIONE
}

@export var offset_rotazione := 0.0
@export var larghezza_albero_cm := 3.0
@export var lunghezza_biella_cm := 10.0
@export var volume_extra_cm := 3.0 
@export var alesaggio_cm = 5.0 # Diametro

var rotazione := 0.0
var rotazione_fase := 0.0
var fase_attuale := ASPIRAZIONE

var posizione_albero := Vector2.ONE * larghezza_albero_cm * Unita.cm
var h_biella_attuale := 0.0
#var h_pistone_attuale_relativa := 0.0
var distanza_pistone_tdc := 0.0 # Distanza del pistone dal TDC e altzza del volume

var numero_moli_aria_attuale := 0.0
var numero_moli_carburante_attuale := 0.0
var numero_moli_scarico_attuale := 0.0
var temperatura_attuale := 1.0
var volume_attuale := 0.1
var pressione_cilindro := 0.0

var numero_moli_carbuante_residuo := 0.0 # questo valore sprirà con una simulazione migliore
var inquinamento_aria_post_combustione := 0.0 # questo valore sprirà con una simulazione migliore
var qnt_aria_su_volume_post_combustione := 0.0 # questo valore sprirà con una simulazione migliore

func _aggiorna_volume():
	volume_attuale = distanza_pistone_tdc * alesaggio_cm * 0.5 * Unita.cm\
			+ volume_extra_cm * Unita.cm * alesaggio_cm * Unita.cm


func _aggiorna_valore_moli(motore : ComponenteMotore):
	# Qui dentro andrebbero eseguiti i calcoli vari per definire quanta aria deve
	# entrare e deve uscire dal motore.
	# Il quantitativo di aria è sinonimo di nummero di moli di aria
	
	if fase_attuale == ASPIRAZIONE:
		# La quantita di aria pulita dipende da quanta ne entra in confronto
		# con il carburante e da qunata sporca ce ne è già dentro.
		# Non calcoliamo l'aria pulità che c'è già perché tanto è uguale
		# a quella che sta per entrare, in futuro il sistem potrà
		# cambiare. Lo stesso vale per quanto carburante non combusto è
		# rimaston nella camera ad occupare spazio.
		numero_moli_aria_attuale = volume_attuale * (1.0 - 1.0 / motore.ecu.miscela_attuale)\
			* PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA * (Input.get_action_strength("pene_temp") + 0.1)\
			#motore.ecu.ottieni_apertura(motore)\
			- numero_moli_scarico_attuale - numero_moli_carbuante_residuo
		if numero_moli_aria_attuale < 0.0 : numero_moli_aria_attuale = 0.0

		# Qui il valore è costante ed è dettato dall'ECU.
		# sarebbe da cambiare il peso specifico ma sbatta
		numero_moli_carburante_attuale = volume_attuale / motore.ecu.miscela_attuale\
			* PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA + numero_moli_carbuante_residuo
	
	
	if fase_attuale == ESPULSIONE:
		# questo calcolo è sbagliato, perché non tiene conto di quanta aria
		# c'era prima dell'espulsione
		numero_moli_aria_attuale = qnt_aria_su_volume_post_combustione * volume_attuale * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA
		numero_moli_scarico_attuale = numero_moli_aria_attuale * inquinamento_aria_post_combustione
		numero_moli_aria_attuale -= numero_moli_scarico_attuale
		numero_moli_carburante_attuale = 0.0 # semplificazione perché mi sono rotto il cazzo
		numero_moli_carbuante_residuo = 0.0

func _aggiorna_temperatura(motore : ComponenteMotore, delta : float):
	if fase_attuale == COMBUSTIONE:
		# TODO: simulazione della propagazione della combustione
		var delta_combustione := (delta / Unita.msec)
		# Incrementa la temperatura e diminuisci il carburante disponibile
		var carburante_da_bruciare := numero_moli_carburante_attuale * delta_combustione

		if numero_moli_carburante_attuale < carburante_da_bruciare:
#			print("Non abbastanza carburante")
			# Se non c'è abbastanza carburante da bruciare,
			# ridimensiona le quantità di carburante bruciato
			carburante_da_bruciare = numero_moli_carburante_attuale

#		print("carburante da bruciare: ", carburante_da_bruciare)
		
		if numero_moli_aria_attuale < QNT_ARIA_REAZIONE_CARBURANTE * carburante_da_bruciare:
#			print("Non abbastanza aria")
			# Se non c'è abbastanza carburante per bruciare l'aria,
			# ridimensiona le quantita di carburante bruciato 
			carburante_da_bruciare = numero_moli_aria_attuale / QNT_ARIA_REAZIONE_CARBURANTE


		# Aumenta la temperatura a seconda di quanto carburante è bruciato
		temperatura_attuale += carburante_da_bruciare * GRADI_PER_MOLE_REAZIONE
		numero_moli_carburante_attuale -= carburante_da_bruciare

		# Diminuisci l'aria disponibile, il carburante l'ha bruciata
		numero_moli_aria_attuale -= QNT_ARIA_REAZIONE_CARBURANTE * carburante_da_bruciare

		# Aumenta i gas di scarico a seconda di quanta aria e quanto carburante sono bruciati
		numero_moli_scarico_attuale += QNT_ARIA_REAZIONE_CARBURANTE * carburante_da_bruciare\
			+ carburante_da_bruciare

		# Nella fase di combustione deve esser bruciato tutto, altrimenti
		# c'è del carburante residuo, conservato in questo valore:
		numero_moli_carbuante_residuo = numero_moli_carburante_attuale
		if numero_moli_aria_attuale > 0.0 :
			inquinamento_aria_post_combustione = numero_moli_scarico_attuale/numero_moli_aria_attuale
		else:
			inquinamento_aria_post_combustione = 0.0
		qnt_aria_su_volume_post_combustione = (numero_moli_aria_attuale+numero_moli_scarico_attuale) / (volume_attuale * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA)

	else:
		#TODO : simulare il raffreddamento del motore
		temperatura_attuale = 1.0


func _aggiorna_pressione():
	var moli_totali = numero_moli_aria_attuale\
		+ numero_moli_carburante_attuale + numero_moli_scarico_attuale
	#print(temperatura_attuale)
	if fase_attuale == COMBUSTIONE || fase_attuale == COMPRESSIONE :
		pressione_cilindro = moli_totali * COSTANTE_GAS_IDEALE\
			* temperatura_attuale / volume_attuale
	else :
		pressione_cilindro = 0.0


func elabora(motore : ComponenteMotore, delta : float):
	_aggiorna_volume()
	_aggiorna_valore_moli(motore)
	_aggiorna_temperatura(motore, delta)
	_aggiorna_pressione()


func ottieni_coppia():
	var area_pistone = pow(alesaggio_cm * Unita.cm * 0.5, 2.0) * PI
	var area_pareti_camera = alesaggio_cm * Unita.cm * PI * distanza_pistone_tdc\
		+ area_pistone * 2.0
	
	# La forza è data dalla pressione per la superficie, ma in questo
	# caso molta forza è sprecata sulle pareti della camera che non toccano
	# il pistone
	var forza : float = pressione_cilindro * area_pistone / area_pareti_camera
	
	var forza_biella = forza * h_biella_attuale / (lunghezza_biella_cm * Unita.cm)
	var vettore_forza_biella = forza_biella *\
		Vector2(posizione_albero.x, -h_biella_attuale).normalized()
	
	return posizione_albero.normalized().orthogonal().dot(vettore_forza_biella)\
		* larghezza_albero_cm * Unita.cm


func imposta_parametri(rotazione : float):
	self.rotazione = OFFSET_BASE_ROTAZIONE + offset_rotazione + rotazione

	if rotazione + offset_rotazione < 0.0 :
		self.rotazione_fase = TAU*2 - fmod(rotazione + offset_rotazione, TAU*2)
	else :
		self.rotazione_fase = fmod(rotazione + offset_rotazione, TAU*2)
	

	if rotazione_fase < PI :
		self.fase_attuale = ASPIRAZIONE
	elif rotazione_fase < TAU :
		self.fase_attuale = COMPRESSIONE
	elif rotazione_fase < TAU + PI :
		self.fase_attuale = COMBUSTIONE
	else:
		self.fase_attuale = ESPULSIONE

	h_biella_attuale = FunzioniMotore.altezza_biella(
		self.rotazione, larghezza_albero_cm * Unita.cm, lunghezza_biella_cm * Unita.cm)
	
	posizione_albero = Vector2(cos(self.rotazione),sin(self.rotazione))\
		* larghezza_albero_cm * Unita.cm
	
	var h_pistone_attuale_relativa = ((larghezza_albero_cm * Unita.cm + lunghezza_biella_cm * Unita.cm) - (h_biella_attuale + posizione_albero.y))
	distanza_pistone_tdc = (larghezza_albero_cm * Unita.cm * 2.0 - h_pistone_attuale_relativa)
