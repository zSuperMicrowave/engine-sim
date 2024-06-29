extends Object
class_name BufferCircolare


var lunghezza := 44100

var buffer := PackedFloat32Array()
var i_scrittura := 0
var i_lettura := 0


func _init(lunghezza : int):
	if lunghezza < 0 : lunghezza = 1
	self.lunghezza = lunghezza
	
	buffer.resize(lunghezza)


func scrivi(val : float):
	i_scrittura += 1
	buffer[i_scrittura % lunghezza] = val


func leggi() -> float:
	i_lettura += 1	
	return buffer[i_lettura % lunghezza]


func leggi_scrivi(val : float):
	var out = leggi()
	scrivi(val)
	return out
