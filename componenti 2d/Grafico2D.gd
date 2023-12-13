extends Node2D
class_name Grafico2D

@export_category("Estetica")
@export var larghezza := 100
@export var altezza := 18.0
@export var spessore_linea := 1.0
@export var colore_sfondo := Color.BLACK
@export var colore_linea := Color.CADET_BLUE

@export_category("Visualizzazione Dati")
@export var velocita := 1.0
@export var valore_massimo := 1.0

var punti_grafico : PackedFloat64Array = []
var ultimo_punto_disegnato := Vector2.ZERO
var valore_y_attuale := 0.0 # Dati che venono inseriti nel grafico
var valore_x_attuale := 0 # Viene aggiornato alla velocita "velocita"

var punti_grafico_vecchio : PackedFloat64Array = []


func _ready():
	punti_grafico.resize(larghezza)

func _draw():
	if punti_grafico.is_empty() or punti_grafico_vecchio.is_empty():
		return
	
	for coord_x in range(larghezza) :
		# Disegna lo sfondo del grafico colonna per colonna
		draw_line(
			Vector2( coord_x + 0.5 , -altezza * 0.5),
			Vector2( coord_x + 0.5 , +altezza * 0.5),
			colore_sfondo)

		# Disegna la linea del grafico unendo i vecchi punti coi nuovi
		var nuovo_punto = Vector2(coord_x + 0.5, punti_grafico_vecchio[coord_x] * altezza*0.5/valore_massimo)
		var nuovo_punto_b = Vector2(coord_x + 0.5, punti_grafico[coord_x] * altezza*0.5/valore_massimo)
		draw_line(
			ultimo_punto_disegnato, nuovo_punto,
			colore_linea, spessore_linea)
		draw_line(
			nuovo_punto_b + Vector2(0.0,-10.0), nuovo_punto_b,
			Color(colore_linea,0.2), spessore_linea)
		ultimo_punto_disegnato = nuovo_punto


func _process(delta):
	# Controlla che ci siano i punti corretti nel grafico
	if punti_grafico.size() != larghezza :
		punti_grafico.resize(larghezza)
	
	for i in range(velocita*larghezza) :
		_aggiorna_grafico()
	
	queue_redraw()


func _aggiorna_grafico():
	valore_x_attuale += 1
	if valore_x_attuale >= larghezza :
		punti_grafico_vecchio = punti_grafico.duplicate()
		valore_x_attuale = 0
	
	punti_grafico.set(valore_x_attuale, -valore_y_attuale)

func invia_dato(dato : float, immediato := false):
	valore_y_attuale = dato
	if immediato:
		_aggiorna_grafico()
