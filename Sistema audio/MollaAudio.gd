extends ComponenteAudio
class_name MollaAudio

var delta = 1.0 / InfoAudio.frequenza_campionamento_hz

@export_category("ComponenteAudio")
@export var campionatore : CampionatorePistone

@export_group("ProprietaMolla")
@export var durezza_modulata := true
@export_range(20.0,8000.0) var moltiplicatore_durezza := 1600
@export_range(0.01,0.999) var attrito := 0.98

var p = 0.0
var f = 0.0


func ottieni_campione() -> float:
	var durezza = moltiplicatore_durezza
	if durezza_modulata :
		durezza *= campionatore.ottieni_riverbero() * 0.01
	
	p *= attrito
	p += campionatore.ottieni_campione()
	
	var f_h = (-durezza * p)
	
	f += f_h * delta
	
	p = p + f
	f *= attrito
	
	return p
