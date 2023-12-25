extends Resource
class_name ComponenteVolano

var inerzia := 1.0 # kg/m^2
@export var raggio := 1.0: # m
	set(valore):
		raggio = valore
		inerzia = 0.5 * massa * pow(raggio,2)
@export var massa := 1.0: # kg
	set(valore):
		massa = valore
		inerzia = 0.5 * massa * pow(raggio,2)
