extends BufferCircolare
class_name BufferLetturaAudio

var compensazione_ritardo_scrittura := 0.1

func _init(lunghezza : int, compensaziona_ritardo_scrittura : float):
	clamp(compensaziona_ritardo_scrittura, 0.0, 1.0)
	self.compensazione_ritardo_scrittura = compensazione_ritardo_scrittura
	super._init(lunghezza)
	i_scrittura = compensaziona_ritardo_scrittura * lunghezza


func scrivi(val : float):
	# Evita che un ritardo nel buffer di lettura causi una sovrascrizione di
	# valori che stanno per esser letti
	if i_scrittura >= i_lettura + lunghezza:
		buffer[i_scrittura % lunghezza] = val
		return

	i_scrittura += 1
	buffer[i_scrittura % lunghezza] = val


func leggi() -> float:
	# Evita che il puntatore di scrittura si trovi indietro rispetto al
	# puntatore di lettura
	if i_lettura > i_scrittura :
		i_scrittura = i_lettura + lunghezza * compensazione_ritardo_scrittura
		return buffer[i_scrittura % lunghezza]

	i_lettura += 1
	return buffer[i_lettura % lunghezza]


func leggi_scrivi(val : float):
	return super.leggi_scrivi(val)
