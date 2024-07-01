extends ComponenteAudio
class_name CombinatoreAudio

@export var componenti_precedenti : Array[ComponenteAudio]
@export var esegui_media := false


func sample_audio(samps : int) -> Array[float]:
	var out : Array[float] = []
	for i in range(samps) :
		out.append(0.0)

	for c in componenti_precedenti :
		var samps_buf := c.sample_audio(samps)
		
		for i in range(samps) :
			out[i] += samps_buf[i]
	
	if esegui_media :
		for i in range(samps) :
			out[i] /= componenti_precedenti.size()

	return out
