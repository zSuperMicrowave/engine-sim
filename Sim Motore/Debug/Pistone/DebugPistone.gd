extends Marker3D
class_name DebugPistone

# Visualizzazione grafica 3D del volume rimanente nel cilindro, distinguendo
# la corsa del pistone dal volume occupato dalla zona d'aria extra in TDC.
# La visualizzazione consente di visionare anche l'attuale fase del
# motore nel ciclo combustione usando materiali diversi


enum {
	FASE_ASPIRAZIONE,
	FASE_COMPRESSIONE,
	FASE_COMBUSTIONE,
	FASE_ESPULSIONE
}

@export var materiale_aspirazione : StandardMaterial3D
@export var materiale_compressione : StandardMaterial3D
@export var materiale_combustione : StandardMaterial3D
@export var materiale_espulsione : StandardMaterial3D


# TEST COMMENTATO:

func _ready():
	imposta(0.05,0.1)


#var t = 0.0
#
#func _process(delta):
#	t += delta
#
#	var s := fmod(t*TAU, TAU*2)
#	var f := FASE_ESPULSIONE
#	if s <= PI :
#		f = FASE_ASPIRAZIONE
#	elif s <= TAU :
#		f = FASE_COMPRESSIONE
#	elif s <= PI*3 :
#		f = FASE_COMBUSTIONE
#
#	aggiorna(sin(t*TAU)*0.1 + 0.1, f)


func imposta(altezza_tdc : float, alesaggio : float) :
	# Imposta le dimensioni e lunghezze dei vari componenti
	# nella visualizzazione grafica del pistone.
	
	$TDC.height = altezza_tdc
	$TDC.radius = alesaggio/2.0
	$TDC.position = Vector3.UP * altezza_tdc * 0.5 
	$cilindro.radius = alesaggio/2.0


func aggiorna(distanza_tdc : float, fase_combustione : int, rotazione:float) :
	# Aggiorna la visualizzazione grafica del volume rimanente
	# nel cilindro.
	
	$cilindro.height = distanza_tdc
	$cilindro.position = Vector3.DOWN * distanza_tdc * 0.5 
	$albero.rotation.x = rotazione

	match fase_combustione:
		FASE_ASPIRAZIONE:
			$cilindro.material = materiale_aspirazione
		FASE_COMPRESSIONE:
			$cilindro.material = materiale_compressione
		FASE_COMBUSTIONE:
			$cilindro.material = materiale_combustione
		FASE_ESPULSIONE:
			$cilindro.material = materiale_espulsione
