extends Resource
class_name ComponenteEcu

# y = rpm
# x = pedale
# canale r è quello usato dalle mappe

@export var velocita_aggiornamento_ecu_hz := 10

@export var rpm_massimi := 12000.0

@export var miscela_piu_povera := 65.0
@export var miscela_piu_ricca := 12.0
@export var mappa_stechiometrica : Texture2D

@export var apertura_minima := 0.0
@export var apertura_massima := 1.0
@export var mappa_apertura : GradientTexture2D

var apertura_attuale := 0.1
var miscela_attuale := 10.0


func elabora(motore : ComponenteMotore) :
	apertura_attuale = _ottieni_apertura(motore)
	miscela_attuale = _ottieni_miscela(motore)


func _ottieni_miscela(motore : ComponenteMotore):
	var pos_mappa := ottieni_posizione_relativa_mappatura(motore)
	
	pos_mappa *= Vector2(mappa_stechiometrica.get_width(), mappa_stechiometrica.get_height())
	var valore := mappa_stechiometrica.get_image().get_pixelv(pos_mappa).r
	return miscela_piu_ricca + (1.0 - valore) * (miscela_piu_povera-miscela_piu_ricca)


func _ottieni_apertura(motore : ComponenteMotore):
	var pos_mappa := ottieni_posizione_relativa_mappatura(motore)
	
	pos_mappa *= Vector2(mappa_apertura.get_width(), mappa_apertura.get_height())
	var valore := mappa_apertura.get_image().get_pixelv(pos_mappa).r
	return apertura_minima + valore * (apertura_massima-apertura_minima)


func ottieni_posizione_relativa_mappatura(motore : ComponenteMotore) -> Vector2:
	var rpm = motore.albero_motore.velocita_angolare / Unita.rpm
	var rpm_relativi = rpm / rpm_massimi
	
	var posizione_pedale = Input.get_action_strength("mouse_sx")
	return clamp(Vector2(posizione_pedale, rpm_relativi),Vector3.ZERO, Vector3.ONE)
