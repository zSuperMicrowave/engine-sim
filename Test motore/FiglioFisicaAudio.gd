extends Node
class_name NodoFisicaAudio

@onready var nodi_figli := get_children() 

func _chiama_loop(delta_fisica_audio):
	for figlio in nodi_figli :
		if figlio is NodoFisicaAudio :
			figlio._chiama_loop()
	_processa_fisica_audio(delta_fisica_audio)

func _processa_fisica_audio(_delta) :
	pass
