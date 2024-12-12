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

func send_return_buffer(buffer : Array[float]):
	var mul = 1.0 / float(componenti_precedenti.size())
	
	var new_buff : Array[float] = []
	for e in buffer :
		new_buff.append(e*mul)
	
	for c in componenti_precedenti:
		if c is Delay or c is CombinatoreAudio :
			c.send_return_buffer(new_buff)
