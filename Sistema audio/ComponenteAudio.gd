extends Node
class_name ComponenteAudio

func sample_audio(samps : int) -> Array[float]:
	printerr("Questa funzione dev'essere sovrascritta in tutti i componenti")
	var out :  Array[float] = [0.0]
	return out

func sample_reverb(samps : int) -> Array[float]:
	printerr("Questa funzione dev'essere sovrascritta almeno
		nel campionatore audio")
	var out :  Array[float] = [0.0]
	return out
