extends Resource

class_name PassaggioTubo

@export_range(0.0, 1.0) var qnt_riflessione_pressione = 0.05
@export_range(0.0, 1000.0) var lunghezza_tratto = 0.1
@export_range(0.0, 10.0) var larghezza_passaggio = 0.1
@export var inerzia_aria := 1.0

@export var pressione_attuale := 0.0
@export var pressione_nuova := 0.0
@export var attenuazione := 1.0
var velocita_cambiamento_pressione := 0.0


func calcola_pressione_nuova(delta : float, passaggio_precedente : PassaggioTubo
		, passaggio_successivo : PassaggioTubo, valore_aggiuntivo := 0.0, flusso_positivo := true):
	# Calcola il valore di pressione_nuova senza applicarlo a pressione_attuale
	# I valori di restrizione sono in realtà una percentuale del passaggio
	# dell'aria
	pressione_attuale = pressione_nuova * delta/lunghezza_tratto
	
	if passaggio_precedente && passaggio_successivo:
		var forza_cambiamento = \
			(passaggio_precedente.pressione_attuale + passaggio_successivo.pressione_attuale)/2\
			- pressione_attuale
		
		velocita_cambiamento_pressione += (forza_cambiamento/inerzia_aria) * delta
		
		pressione_nuova += velocita_cambiamento_pressione * delta
		
	elif passaggio_successivo:
		var forza_cambiamento = \
			passaggio_successivo.pressione_attuale - pressione_attuale
		
		velocita_cambiamento_pressione += (forza_cambiamento/inerzia_aria) * delta
		
		pressione_nuova += velocita_cambiamento_pressione * delta
		
	elif passaggio_precedente:
		var forza_cambiamento = \
			passaggio_precedente.pressione_attuale - pressione_attuale
		
		velocita_cambiamento_pressione += (forza_cambiamento/inerzia_aria) * delta
		
		pressione_nuova += velocita_cambiamento_pressione * delta 
	
	pressione_nuova += valore_aggiuntivo
	
	pressione_nuova *= (1.0-clamp(delta*attenuazione,0.0,1.0))
