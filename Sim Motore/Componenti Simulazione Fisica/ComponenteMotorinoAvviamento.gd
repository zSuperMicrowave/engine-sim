extends Resource
class_name ComponenteMotorinoAvviamento

@export var riduzione := 2.0
@export var max_velocita_rpm := 2800.0
@export var coppia_nm := 50.0

var coppia_attuale := 0.0
var velocita_attuale := 0.0


func elabora(motore : ComponenteMotore, delta : float):
	var max_velocita = max_velocita_rpm * Unita.rpm
	var vel = clamp(velocita_attuale, 0.0, max_velocita -1.0)
	
	if motore.batteria_connessa and Input.is_action_pressed("invio"):
		# Un motore elettrico è più forte quando va più veloce
		# y = coppia / (valore - velocita)
		coppia_attuale = coppia_nm / (max_velocita - vel)
		if velocita_attuale > max_velocita-1.0 :
			coppia_attuale /= (velocita_attuale - (max_velocita-2.0))*20.0
		
	else :
		# Approssimazione energia trattenuta da condensatore
		coppia_attuale = lerp(coppia_attuale, 0.0, clamp(delta * 2.0, 0.0, 1.0))


func ottieni_coppia():
	return coppia_attuale * riduzione

func imposta_parametri(velocita : float):
	# TODO: SIMULARE L'ATTACCARSI E STACCARSI DEL MOTORINO
	#       E CONSEGUENTEMENTE ANCHE L'INERZIA
	velocita_attuale = velocita * riduzione
