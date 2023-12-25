extends Node3D


@export var valore_massimo := 1.0




func _ready():
	pass


var t := 0.0

func _process(delta):
	t += delta * 0.1
	scrivi_float(sin(t*TAU))


func scrivi_float(valore : float):
	$etichetta.text = str(valore)

	valore = valore/valore_massimo

	$tratto.position = Vector3.UP * valore/2
	$tratto.height = valore
	$punta.position = Vector3.UP * valore
	if valore < 0.0 : $punta.rotation = Vector3(PI,0,0)
	else : $punta.rotation = Vector3.ZERO

func scrivi_vettore(vettore : Vector3):
	var valore = vettore.distance_to(Vector3.ZERO)
	$etichetta.text = str(valore)
	
	var vettore_n = vettore/valore_massimo
	var valore_n = valore/valore_massimo
	
	$tratto.position = vettore_n/2
	$tratto.height = valore_n
	$punta.position = vettore_n
