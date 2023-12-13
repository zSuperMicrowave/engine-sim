extends Sprite2D


@export_category("Visualizzazione")
@export var gradiente_intensita : Gradient
@export var valore_minimo := 0.0
@export var valore_massimo := 1.0

@export_category("Monitoraggio")
@export var nodo_da_monitorare : Node
@export var parametro_da_monitorare := ""

var valore_forzato := -1.0

func _ready():
	if nodo_da_monitorare == null:
		push_error("Il nodo da monitorare selezionato non è valido.")
	elif nodo_da_monitorare.get(parametro_da_monitorare) == null:
		push_warning("Il parametro da monitorare è uguale a NULL.")


func _process(_delta):
	if valore_forzato != -1.0:
		modulate = gradiente_intensita.sample(
		abs( (valore_forzato - valore_minimo) / valore_massimo )
		)
		return
	
	if !nodo_da_monitorare:
		modulate = Color.BLACK
		return


	var valore = nodo_da_monitorare.get(parametro_da_monitorare)
	
	if valore == null:
		modulate = Color.BLACK
		return

	modulate = gradiente_intensita.sample(
		abs( (valore - valore_minimo) / valore_massimo )
	)
