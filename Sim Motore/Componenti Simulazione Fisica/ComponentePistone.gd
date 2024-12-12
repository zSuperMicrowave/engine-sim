extends Resource
class_name ComponentePistone

const OFFSET_BASE_ROTAZIONE := -PI/2.0
const PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA := 42.698
const MOLTIPLICATORE_IRREALISTICO_ENTRATA_ARIA := 10000

const NEW_CODE := false

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

var inizializzazione = true

var rotazione := 0.0
var rotazione_fase := 0.0
var fase_attuale := ASPIRAZIONE

var posizione_albero := Vector2.ONE * larghezza_albero_cm * Unita.cm
var h_biella_attuale := 0.0
var distanza_pistone_tdc := 0.0 # Distanza del pistone dal TDC e altzza del volume

var aria_cilindro := AriaMotore.new()


func inizializza():
	aria_cilindro.inizializza(distanza_pistone_tdc, alesaggio_cm, volume_extra_cm)


func elabora(motore : ComponenteMotore, delta : float):
	if inizializzazione:
		inizializza()
		inizializzazione = false
	
	_aggiorna_volume()
	_aggiorna_moli(motore, delta)
	_aggiorna_temperatura(motore, delta)


func _aggiorna_volume():
	aria_cilindro.volume = \
		distanza_pistone_tdc * pow(alesaggio_cm  * Unita.cm * 0.5,2.0) * PI\
		+ volume_extra_cm * Unita.cm * pow(alesaggio_cm * 0.5 * Unita.cm,2.0) * PI

	aria_cilindro.ricalcola_pressione()


func _aggiorna_moli(motore : ComponenteMotore, delta : float):
	# Qui dentro vengono eseguiti calcoli vari per definire quanti e che tipi
	# di gas entrano ed escono dal cilindro.
	if not NEW_CODE :
		var flusso_in = clamp(delta * 1000 * motore.ecu.apertura_attuale\
			* portata_entrata_aria, 0.0, 1.0)
		var flusso_out = clamp(delta * 1000\
			* portata_uscita_aria, 0.0, 1.0)

		if fase_attuale == ASPIRAZIONE:
			var pressione_obiettivo = aria_cilindro.pressione * (1.0-flusso_in)\
				+ motore.pressione_atmosferica * flusso_in

			var moli_aggiuntive = aria_cilindro.ottieni_moli_necessarie(pressione_obiettivo)

			if moli_aggiuntive > 0.0 :
				# Il valore di moli deve essere maggiore di 0

				aria_cilindro.moli_ossigeno +=\
					moli_aggiuntive * (1.0 - 1.0 / motore.ecu.miscela_attuale)
				aria_cilindro.moli_benzina +=\
					 moli_aggiuntive * (1.0 / motore.ecu.miscela_attuale)

				aria_cilindro.pressione = pressione_obiettivo # IMPOSTA PRESSIONE
				aria_cilindro._moli_totali += moli_aggiuntive # IMPOSTA MOLI

		if fase_attuale == ESPULSIONE:
			var pressione_obiettivo = aria_cilindro.pressione * (1.0-flusso_out)\
				+ motore.pressione_atmosferica * flusso_out

			aria_cilindro.pressione = pressione_obiettivo

			aria_cilindro.ricalcola_moli()
	else :
		if fase_attuale == ASPIRAZIONE :
			if motore.pressione_atmosferica < aria_cilindro.pressione :
				# Se la pressione interna è maggiore (caso raro)
				aria_cilindro.pressione -= calcola_flusso(
					motore.pressione_atmosferica - aria_cilindro.pressione,
					portata_entrata_aria * motore.ecu.apertura_attuale
					) * min(delta,1.0)
				aria_cilindro.ricalcola_moli()
			else :
				# Se è tutto ordinario e l'aria deve entrareù
				var pressione_obiettivo : float =\
					aria_cilindro.pressione + calcola_flusso(
						motore.pressione_atmosferica - aria_cilindro.pressione,
						portata_entrata_aria * motore.ecu.apertura_attuale) * min(delta * MOLTIPLICATORE_IRREALISTICO_ENTRATA_ARIA,1.0)

				var moli_aggiuntive : float =\
				aria_cilindro.ottieni_moli_necessarie(
					pressione_obiettivo)

				aria_cilindro.moli_ossigeno +=\
					moli_aggiuntive * (1.0 - 1.0 / motore.ecu.miscela_attuale)
				aria_cilindro.moli_benzina +=\
					 moli_aggiuntive * (1.0 / motore.ecu.miscela_attuale)
				aria_cilindro.pressione = pressione_obiettivo # IMPOSTA PRESSIONE
				aria_cilindro._moli_totali += moli_aggiuntive # IMPOSTA MOLI

		elif fase_attuale == ESPULSIONE :
			if motore.pressione_atmosferica < aria_cilindro.pressione :
				# Se la pressione interna è maggiore
				aria_cilindro.pressione -= calcola_flusso(
					motore.pressione_atmosferica - aria_cilindro.pressione,
					portata_uscita_aria
					) * min(delta * MOLTIPLICATORE_IRREALISTICO_ENTRATA_ARIA,1.0)
				aria_cilindro.ricalcola_moli()
			else :
				# Se la pressione interna è minore (caso raro)
				var pressione_obiettivo : float =\
					aria_cilindro.pressione + calcola_flusso(
						motore.pressione_atmosferica - aria_cilindro.pressione,
						portata_uscita_aria) * min(delta ,1.0)
				
				var moli_aggiuntive : float =\
				aria_cilindro.ottieni_moli_necessarie(
					pressione_obiettivo)
				
				aria_cilindro.moli_gas_scarico += moli_aggiuntive
				
				aria_cilindro.pressione = pressione_obiettivo # IMPOSTA PRESSIONE
				aria_cilindro._moli_totali += moli_aggiuntive # IMPOSTA MOLI



func calcola_flusso(p_diff:float,section_area:float):
	var out = 0.1206 * sqrt(abs(p_diff)) * section_area
	#print(out)
	return out * PESO_SPECIFICO_SU_MASSA_MOLARE_ARIA

var temp_camera := 273.0
func _aggiorna_temperatura(motore : ComponenteMotore, delta : float):
	
	var diff = abs(temp_camera - aria_cilindro.temperatura)
	
	if fase_attuale == COMBUSTIONE:
		if motore.batteria_connessa and\
		rotazione + deg_to_rad(offset_rotazione) >= 0.0:
			# questa funzione sotto è rotta (probabilmente)
			aria_cilindro.esegui_combustione(delta * 250 \
				/ ( alesaggio_cm * larghezza_albero_cm * Unita.cm2) )
		
	elif fase_attuale == ASPIRAZIONE:
#		aria_cilindro.temperatura = motore.temperatura_esterna
		aria_cilindro.temperatura -= delta * 200\
			* (aria_cilindro.temperatura - motore.temperatura_esterna)
		if aria_cilindro.temperatura < motore.temperatura_esterna :
			aria_cilindro.temperatura = motore.temperatura_esterna
		
	else:
		aria_cilindro.temperatura = lerpf(aria_cilindro.temperatura, temp_camera, delta * diff * 0.01)
#		aria_cilindro.temperatura -= delta * 0.01\
#			* (aria_cilindro.temperatura - motore.temperatura_esterna)
#		if aria_cilindro.temperatura < motore.temperatura_esterna :
#			aria_cilindro.temperatura = motore.temperatura_esterna

	temp_camera = lerpf(temp_camera, aria_cilindro.temperatura, delta * 0.001)
	aria_cilindro.temperatura = lerpf(aria_cilindro.temperatura, temp_camera, delta * 0.001)
	
#	if randf() >0.999:
#		print(temp_camera - 273)
	
	temp_camera = lerpf(temp_camera, motore.temperatura_esterna, delta * 0.001)
	
	aria_cilindro.ricalcola_pressione()


func ottieni_coppia(motore : ComponenteMotore):
#	if fase_attuale == ASPIRAZIONE : return 0.0 # DEBUG
#	if fase_attuale == ESPULSIONE : return 0.0 # DEBUG
#	if fase_attuale == COMPRESSIONE : return 0.0 # DEBUG
#	if fase_attuale != COMBUSTIONE : return 0.0 # DEBUG
	
	# La forza è data dalla pressione per la superficie, ma in questo
	# caso molta forza è sprecata sulle pareti della camera che non toccano
	# il pistone
	var area_pistone = pow(alesaggio_cm * Unita.cm * 0.5, 2.0) * PI
	var area_pareti_camera = alesaggio_cm * Unita.cm * PI * distanza_pistone_tdc\
		+ area_pistone * 2.0
	var diff_pressione = aria_cilindro.pressione - motore.pressione_atmosferica
	
	var forza : float = diff_pressione * area_pistone / area_pareti_camera

	var forza_biella = forza * h_biella_attuale / (lunghezza_biella_cm * Unita.cm)
	var vettore_forza_biella = forza_biella *\
		Vector2(posizione_albero.x, -h_biella_attuale).normalized()

	return posizione_albero.normalized().orthogonal().dot(vettore_forza_biella)\
		* larghezza_albero_cm * Unita.cm


func imposta_parametri(rotazione : float):
	self.rotazione = OFFSET_BASE_ROTAZIONE + deg_to_rad(offset_rotazione) + rotazione

	if rotazione + deg_to_rad(offset_rotazione) < 0.0 :
		self.rotazione_fase = TAU*2 - fmod(-(rotazione + deg_to_rad(offset_rotazione)), TAU*2)
	else :
		self.rotazione_fase = fmod(rotazione + deg_to_rad(offset_rotazione), TAU*2)

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
