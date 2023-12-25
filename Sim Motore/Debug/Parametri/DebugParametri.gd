extends GridContainer
class_name GrigliaDebugParametri

# Aggiunge e aggiorna in automatico nell'UI parametri di Debug in
# una struttura a griglia con una sola funzione.
# I parametri creati non sono eliminabili.


@export_category("Aspetto")
@export var larghezza_minima := 200.0
@export var altezza_minima := 50.0
@export var stile_testo : StyleBoxFlat

# Chiave : nome del parametro
# Valore : Riferimento al nodo label
var parametri := Dictionary()


# LA ZONA COMMENTATA ESISTE SOLO A FINE DI TEST

#var t = 0.0
#
#func _process(delta):
#	t += delta
#	if t < 7.0 :
#		scrivi_parametro("Timer prima dei sette secondi", t)
#	else :
#		scrivi_parametro("Timer dopo dei sette secondi", t)
#		scrivi_parametro("Timer prima dei sette secondi", sin(t))
#	scrivi_parametro("a", cos(t*2))
#	scrivi_parametro("b", cos(t*2))
#	scrivi_parametro("c", cos(t*2))
#	scrivi_parametro("d", cos(t*2))
#	scrivi_parametro("e", cos(t*2))


func scrivi_parametro(nome : String, valore):
	if not parametri.has(nome) :
		# Se non esiste alcun nodo contenente il parametro, creane uno nuovo.
		var nodo_parametro := Label.new()
		nodo_parametro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nodo_parametro.size_flags_vertical = Control.SIZE_FILL
		nodo_parametro.custom_minimum_size.x = larghezza_minima
		nodo_parametro.custom_minimum_size.y = altezza_minima
		nodo_parametro.add_theme_stylebox_override("normal", stile_testo)
		add_child(nodo_parametro)
		
		parametri.merge({nome : nodo_parametro})

	if valore is float : valore = "%.2f" % valore
	parametri[nome].text = nome + ": " + str(valore)
