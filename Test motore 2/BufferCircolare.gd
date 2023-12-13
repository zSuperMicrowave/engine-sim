extends Object
class_name BufferCircolare


var lunghezza := 44100

var buffer := PackedFloat32Array()
var i_scrittura := 0
var i_lettura := 0

func _init(lunghezza : int):
	self.lunghezza = lunghezza
	buffer.resize(lunghezza)


func scrivi(val : float):
	i_scrittura += 1
	if i_scrittura >= lunghezza:
		i_scrittura = 0

	buffer[i_scrittura] = val


func leggi() -> float:
	i_lettura += 1
	if i_lettura >= lunghezza:
		i_lettura = 0

	return buffer[i_lettura]

func scrivi_leggi(val : float):
	var out = leggi()
	scrivi(val)
	return out
