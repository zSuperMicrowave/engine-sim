extends Object
class_name AriaMotore

const COSTANTE_GAS_IDEALE := 8.314

const QNT_OSSIGENO_PER_BENZINA := 12.5
const TEMP_COMBUSTIONE_SPONTANEA_BENZINA := 523.15
const TEMP_ENTALPIA_BENZINA := 4000.0 # per ora è un valore arbitrario
#const QNT_OSSIGENO_PER_DIESEL := 12.5
#const TEMP_COMBUSTIONE_SPONTANEA_DIESEL := 493.15
#const TEMP_ENTALPIA_DIESEL := 4000.0

var moli_ossigeno := 0.0 :
	set(valore):
		moli_ossigeno = valore
		moli_totali = moli_ossigeno + moli_benzina + moli_gas_scarico
var moli_gas_scarico := 0.0 :
	set(valore):
		moli_gas_scarico = valore
		moli_totali = moli_ossigeno + moli_benzina + moli_gas_scarico
var moli_benzina := 0.0 :
	set(valore):
		moli_benzina = valore
		moli_totali = moli_ossigeno + moli_benzina + moli_gas_scarico
#var moli_diesel := 0.0 # Inutilizzato per adesso

var temperatura := 0.0 :
	set(valore):
		temperatura = valore
		pressione = (moli_totali * COSTANTE_GAS_IDEALE * temperatura) / volume

var pressione := 0.0 :
	set(valore):
		pressione = valore
		temperatura = (pressione * volume) / (moli_totali * COSTANTE_GAS_IDEALE)

var moli_totali := 0.0 :
	set(valore):
		printerr("La variabile \"moli_totali\" non è modificabile.")

var volume := 0.0 :
	set(valore):
		volume = valore
		pressione = (moli_totali * COSTANTE_GAS_IDEALE * temperatura) / volume


#func puo_comburere_spontaneamente(
#	pressione : float, volume : float) -> bool:
#
#	var temperatura = pressione * volume /\
#		(moli_totali * COSTANTE_GAS_IDEALE)
#
#	return (temperatura >= TEMP_COMBUSTIONE_SPONTANEA_BENZINA)
#
#
#func avvia_combustione() -> float:
#	# Restituisce la temperatura
#	return 0.0
