extends RefCounted
class_name AriaMotore

const COSTANTE_GAS_IDEALE := 8.314

const QNT_OSSIGENO_PER_BENZINA := 12.5
const TEMP_COMBUSTIONE_SPONTANEA_BENZINA := 523.15
const TEMP_ENTALPIA_BENZINA := 40000.0 # per ora è un valore arbitrario
#const QNT_OSSIGENO_PER_DIESEL := 12.5
#const TEMP_COMBUSTIONE_SPONTANEA_DIESEL := 493.15
#const TEMP_ENTALPIA_DIESEL := 4000.0

var ignora_avvisi=true

var moli_ossigeno := 0.001 :
	set(valore):
		moli_ossigeno = valore
		if moli_ossigeno < -0.0000000001 :
			if !ignora_avvisi: printerr("moli_ossigeno minore di 0")
			moli_ossigeno = 0.0

var moli_gas_scarico := 0.001 :
	set(valore):
		moli_gas_scarico = valore
		if moli_gas_scarico < -0.0000000001 : 
			if !ignora_avvisi: printerr("moli_gas_scarico minore di 0")
			moli_gas_scarico = 0.0

var moli_benzina := 0.001 :
	set(valore):
		moli_benzina = valore
		if moli_benzina < -0.0000000001 : 
			if !ignora_avvisi: printerr("moli_benzina minore di 0")
			moli_benzina = 0.0

var temperatura := 300.15
var pressione := 101325.0
var _moli_totali := 0.003
var volume := 0.00007



func inizializza(distanza_pistone_tdc, alesaggio_cm, altezza_extra_cm):
	volume = (distanza_pistone_tdc + altezza_extra_cm) *\
		pow(alesaggio_cm  * Unita.cm * 0.5,2.0) * PI
	
	var nuovo_moli_totali = pressione * volume\
		/ (COSTANTE_GAS_IDEALE * temperatura)
	
	moli_ossigeno = nuovo_moli_totali / 3
	moli_benzina = nuovo_moli_totali / 3
	moli_gas_scarico = nuovo_moli_totali / 3
	
	_moli_totali = nuovo_moli_totali


func ricalcola_somma_moli():
	_moli_totali = moli_ossigeno + moli_benzina + moli_gas_scarico

func ricalcola_pressione():
	pressione = (_moli_totali * COSTANTE_GAS_IDEALE * temperatura) / volume
	if pressione > 8000000.0 :
		printerr("Pressione elevata.")
		printerr("Moli: ",_moli_totali," b: ",moli_benzina," o: ", moli_ossigeno," s: ", moli_gas_scarico)
#	elif randf() > 0.999:
#		print("Moli: ",_moli_totali," b: ",moli_benzina," o: ", moli_ossigeno," s: ", moli_gas_scarico)
	if is_nan(pressione) or is_inf(pressione) :
		printerr("pressione infinita")
		pressione = 10.0

func ricalcola_temperatura():
	temperatura = (pressione * volume) / (_moli_totali * COSTANTE_GAS_IDEALE)
	if is_nan(temperatura) or is_inf(temperatura) :
		printerr("temperatura infinita")
		temperatura = 0.0

func ricalcola_moli():
	var moli = (pressione * volume) / (COSTANTE_GAS_IDEALE * temperatura)
	imposta_moli_totali(moli)

func ottieni_moli_necessarie(pressione_desiderata : float):
	var moli = (pressione_desiderata * volume) / (COSTANTE_GAS_IDEALE * temperatura)
	return moli - _moli_totali


func imposta_moli_totali(valore : float):
	if _moli_totali != 0.0:
		var perc_ossigeno = moli_ossigeno / _moli_totali
		var perc_benzina = moli_benzina / _moli_totali
		var perc_scarico = moli_gas_scarico / _moli_totali
		
#		print("perc_ossigeno: ", perc_ossigeno)
#		print("perc_benzina: ", perc_benzina)
#		print("perc_scarico: ", perc_scarico)
		
		moli_ossigeno = valore * perc_ossigeno
		moli_benzina = valore * perc_benzina
		moli_gas_scarico = valore * perc_scarico
	else:
		moli_ossigeno = valore / 3.0
		moli_benzina = valore / 3.0
		moli_gas_scarico = valore / 3.0
	
	_moli_totali = valore


func aumenta_moli_totali(valore:float):
	imposta_moli_totali(_moli_totali + valore)

func aumenta_moli_totali_rapido(valore:float):
	moli_ossigeno += valore/3
	moli_benzina += valore/3
	moli_gas_scarico += valore/3

func moli_totali():
	return _moli_totali

func ottieni_validita_formula():
	var valida = (pressione*volume)\
		/ (_moli_totali * COSTANTE_GAS_IDEALE * temperatura)
	return valida

func esegui_combustione(velocita : float):
	# QUESTO CODICE È ROTTO
	# Modifica solo la temperatura, chiamare ricalcola_pressione() dopo questo
	velocita = clamp(velocita,0.0,1.0)
	
	var risultato_combustione =\
		moli_benzina - moli_ossigeno / QNT_OSSIGENO_PER_BENZINA
	
	var moli_ossigeno_bruciate := 0.0
	var moli_benzina_bruciate := 0.0

	if risultato_combustione < 0.0 :
		# L'ossiegeno è più del carburante
		moli_ossigeno_bruciate = moli_ossigeno\
			+ risultato_combustione * QNT_OSSIGENO_PER_BENZINA
		moli_benzina_bruciate = moli_benzina
	else :
		# Il carburante è più dell'ossigeno
		moli_ossigeno_bruciate = moli_ossigeno
		moli_benzina_bruciate = moli_benzina\
			- risultato_combustione
	
	moli_ossigeno_bruciate *= velocita
	moli_benzina_bruciate *= velocita
	var moli_totali_bruciate = moli_ossigeno_bruciate + moli_benzina_bruciate

	# Applica
	moli_ossigeno = moli_ossigeno - moli_ossigeno_bruciate
	moli_benzina = moli_benzina - moli_benzina_bruciate
	moli_gas_scarico += moli_totali_bruciate

	temperatura += TEMP_ENTALPIA_BENZINA * moli_totali_bruciate
	
	
	
	if moli_totali_bruciate < -0.00000001 :
		printerr("moli bruciate: ", moli_totali_bruciate)
	
	if temperatura < 0.0 :
		printerr("il codice è rotto, temperatura minore di zero")
		temperatura = 300

#func puo_comburere_spontaneamente(
#	pressione : float, volume : float) -> bool:
#
#	var temperatura = pressione * volume /\
#		(_moli_totali * COSTANTE_GAS_IDEALE)
#
#	return (temperatura >= TEMP_COMBUSTIONE_SPONTANEA_BENZINA)
#
#
#func avvia_combustione() -> float:
#	# Restituisce la temperatura
#	return 0.0
