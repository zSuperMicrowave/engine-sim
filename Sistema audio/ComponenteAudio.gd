extends Node
class_name ComponenteAudio

func ottieni_campione() -> float:
	if randf() > 0.5 :
		return randf() * 2 - 1
	else :
		return 0.0
