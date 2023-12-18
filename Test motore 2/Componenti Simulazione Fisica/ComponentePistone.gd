extends Resource
class_name ComponentePistone

const OFFSET_BASE_ROTAZIONE := -PI/2.0
const PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA := 42.698
const COSTANTE_GAS_IDEALE := 8.314
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
@export var portata_entrata_aria := 1.0
@export var portata_uscita_aria := 1.0

var flusso_aspirazione := 0.0

var inizializzazione = true

var rotazione := 0.0
var rotazione_fase := 0.0
var fase_attuale := ASPIRAZIONE

var posizione_albero := Vector2.ONE * larghezza_albero_cm * Unita.cm
var h_biella_attuale := 0.0
#var h_pistone_attuale_relativa := 0.0
var distanza_pistone_tdc := 0.0 # Distanza del pistone dal TDC e altzza del volume

var aria_cilindro := AriaMotore.new()



func inizializza():
	aria_cilindro.inizializza(distanza_pistone_tdc, alesaggio_cm, volume_extra_cm)


func elabora(motore : ComponenteMotore, delta : float):
	if inizializzazione:
		inizializza()
		inizializzazione = false
	
	_aggiorna_volume()
	_aggiorna_valore_moli(motore, delta)
	_aggiorna_temperatura(motore, delta)



func _aggiorna_volume():
	aria_cilindro.volume = distanza_pistone_tdc *\
		pow(alesaggio_cm  * Unita.cm * 0.5,2.0) * PI\
		+ volume_extra_cm * Unita.cm * alesaggio_cm * Unita.cm


func _aggiorna_valore_moli(motore : ComponenteMotore, delta : float):
	# Qui dentro andrebbero eseguiti i calcoli vari per definire quanta aria deve
	# entrare e deve uscire dal motore.
	# Il quantitativo di aria è sinonimo di nummero di moli di aria
	
	
	# TODO : CALCOLARE IL FLUSSO IN MANIERA PIU REALISTICA
	flusso_aspirazione = (motore.pressione_atmosferica - aria_cilindro.pressione)\
			* delta / PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA
	
	if fase_attuale == ASPIRAZIONE:
		
		if flusso_aspirazione > 0.0 and\
			aria_cilindro.pressione < motore.pressione_atmosferica:
			
			aria_cilindro.moli_ossigeno += flusso_aspirazione * portata_entrata_aria\
				* (1.0 - 1.0 / motore.ecu.miscela_attuale) * motore.ecu.apertura_attuale
			aria_cilindro.moli_benzina += flusso_aspirazione * portata_entrata_aria\
				* (1.0 / motore.ecu.miscela_attuale) * motore.ecu.apertura_attuale
			
			# APPLICA
			aria_cilindro.ricalcola_somma_moli()
			aria_cilindro.ricalcola_pressione()
			
			# Controllo di sicurezza
			if aria_cilindro.pressione > motore.pressione_atmosferica:
				aria_cilindro.pressione = motore.pressione_atmosferica
				# APPLICA
				aria_cilindro.ricalcola_somma_moli()
				aria_cilindro.ricalcola_pressione()
	
	if fase_attuale == ESPULSIONE:
		
		if flusso_aspirazione < 0.0 and\
			aria_cilindro.pressione > motore.pressione_atmosferica:
			
			aria_cilindro.aumenta_moli_totali(flusso_aspirazione * portata_uscita_aria)
			
			# APPLICA
			aria_cilindro.ricalcola_somma_moli()
			aria_cilindro.ricalcola_pressione()
			
			# Controllo di sicurezza
			if aria_cilindro.pressione < motore.pressione_atmosferica:
				aria_cilindro.pressione = motore.pressione_atmosferica
				# APPLICA
				aria_cilindro.ricalcola_somma_moli()
				aria_cilindro.ricalcola_pressione()


func _aggiorna_temperatura(motore : ComponenteMotore, delta : float):
	if fase_attuale == COMBUSTIONE:
		if motore.batteria_connessa:
			# questa funzione sotto è rotta (probabilmente)
			aria_cilindro.esegui_combustione(delta * 250/alesaggio_cm)
		
	elif fase_attuale == ASPIRAZIONE:
		aria_cilindro.temperatura -= delta * 200\
			* (aria_cilindro.temperatura - motore.temperatura_esterna)
		if aria_cilindro.temperatura < motore.temperatura_esterna :
			aria_cilindro.temperatura = motore.temperatura_esterna
		
	else:
		aria_cilindro.temperatura -= delta * 10\
			* (aria_cilindro.temperatura - motore.temperatura_esterna)
		if aria_cilindro.temperatura < motore.temperatura_esterna :
			aria_cilindro.temperatura = motore.temperatura_esterna
	
	aria_cilindro.ricalcola_pressione()


func ottieni_coppia(motore : ComponenteMotore):
#	if fase_attuale == ASPIRAZIONE : return 0.0 # temporaneo
#	if fase_attuale == ESPULSIONE : return 0.0 # temporaneo
#	if fase_attuale == COMPRESSIONE : return 0.0 # DEBUG
	
	var area_pistone = pow(alesaggio_cm * Unita.cm * 0.5, 2.0) * PI
	var area_pareti_camera = alesaggio_cm * Unita.cm * PI * distanza_pistone_tdc\
		+ area_pistone * 2.0
	
	# La forza è data dalla pressione per la superficie, ma in questo
	# caso molta forza è sprecata sulle pareti della camera che non toccano
	# il pistone
	var diff_pressione = aria_cilindro.pressione - motore.pressione_atmosferica
	#print("aa ",diff_pressione)
	var forza : float = diff_pressione * area_pistone / area_pareti_camera
	
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
