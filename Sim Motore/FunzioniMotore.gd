extends Node

# Queste funzioni sono pensate per essere ottimizzate, pertanto sono presenti
# ridondanze e tecniche di programmazione poco auto-esplicative


func altezza_pistone(angolo_albero_rad : float, lalbero : float, lbiella : float):
	# TODO: ottimizzare
	return altezza_biella(angolo_albero_rad, lalbero, lbiella)\
		 + altezza_albero(angolo_albero_rad, lalbero)


func altezza_biella(angolo_albero_rad : float, lalbero : float, lbiella : float):
	# TODO: ottimizzare
	return sqrt(pow(lbiella,2)-pow(cos(angolo_albero_rad)*lalbero,2))


func altezza_albero(angolo_albero_rad : float, lalbero : float):
	# TODO: ottimizzare
	return sin(angolo_albero_rad)*lalbero


func angolo_biella(angolo_albero_rad : float, lalbero : float, lbiella : float):
	# Coordinata x dell'albero motore all'angolo definito
	var x_albero := cos(angolo_albero_rad) * lalbero
	# Coordinata y della biella in riferimento alla sua base
	var y_biella := sqrt(lbiella*lbiella - x_albero*x_albero)

	# Angolo = tan^-1(h/x)
	return atan(y_biella/x_albero)
