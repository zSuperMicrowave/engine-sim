extends ComponenteAudio
class_name CombinatoreAudio

@export var componenti_precedenti : Array[ComponenteAudio]
@export var esegui_media := false


func ottieni_campione() -> float :
	var risultato : float = 0.0
	
	for c in componenti_precedenti :
		risultato += c.ottieni_campione()
	
	if esegui_media :
		risultato /= componenti_precedenti.size()
	
	return risultato
