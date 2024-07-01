extends ComponenteAudio
class_name CombinatoreAudio

@export var componenti_precedenti : Array[ComponenteAudio]
@export var esegui_media := false
var threads : Array[Thread] = []

func _enter_tree():
	for c in componenti_precedenti:
		threads.append(Thread.new())

func sample_audio(samps : int) -> Array[float]:
	var out : Array[float] = []
	for i in range(samps) :
		out.append(0.0)

	for i in range(componenti_precedenti.size()) :
		threads[i].start(Callable(componenti_precedenti[i],"sample_audio").bind(samps))
	
	for i in range(componenti_precedenti.size()) :
		var samps_buf : Array[float] = threads[i].wait_to_finish()
		for j in range(samps) :
			out[j] += samps_buf[j]
	
	if esegui_media :
		for i in range(samps) :
			out[i] /= componenti_precedenti.size()

	return out
