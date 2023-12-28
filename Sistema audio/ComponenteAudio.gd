extends Node
class_name ComponenteAudio

@export_category("ComponenteAudio")
@export_range(0,1) var ritardo_sec : float

var _buffer_interno : Array[BufferCircolare] = []


func crea_buffer_interno() -> int:
	# Crea un buffer interno e ne restituisce il suo id
	var lunghezza : int\
		= round(ritardo_sec * InfoAudio.frequenza_campionamento_hz)
	if lunghezza < 1 : lunghezza = 1

	_buffer_interno.append(BufferCircolare.new(lunghezza))

	return _buffer_interno.size() -1


func scrivi_leggi_buffer_interno(id : int, val : float) -> float:
	# Scrive e legge
	return _buffer_interno[id].scrivi_leggi(val)


func scrivi_buffer_interno(id : int, val : float) -> void:
	# Scrive
	_buffer_interno[id].scrivi(val)


func leggi_buffer_interno(id : int) -> float:
	# Legge
	return _buffer_interno[id].leggi()


func elimina_buffer_interno(id : int) -> void:
	# Porta a null il buffer specificato e se è possibile snellisci la lsita
	# di buffer presenti eliminando tutti quelli a null
	_buffer_interno[id] = null

	var array_svuotabile = true
	for i in range(_buffer_interno.size() - id) :
		if _buffer_interno[i] != null:
			array_svuotabile = false
			break
	
	if array_svuotabile : _buffer_interno.resize(id)


func elimina_lista_buffer_interni() -> void:
	# Distruggi tutto
	_buffer_interno.clear()


func ottieni_campione(id : float = 0.0):
	# Sovrascrivimi
	printerr("Sovrascrivimiiiii porcodioooo")
	return 0.0
