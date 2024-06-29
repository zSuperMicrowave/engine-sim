extends Node
class_name ComponenteAudio

func sample_audio() -> float:
	printerr("Questa funzione dev'essere sovrascritta in tutti i componenti")

	if randf() > 0.5 :
		return randf() * 2 - 1
	else :
		return 0.0

func sample_reverb() -> float:
	printerr("Questa funzione dev'essere sovrascritta almeno
		nel campionatore audio")

	return 1.0
