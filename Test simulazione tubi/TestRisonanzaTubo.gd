extends NodoFisicaAudio

@export var velocita_simulazione := 11025

@export var audio : AudioStreamWAV

@export var passaggi_tubo : Array[PassaggioTubo]

@export var buffer : BufferFisicaAudio

@export var frequenza := 440.0
var t = 0.0

func _processa_fisica_audio(delta):
	
	aggiorna_risonanza(delta)

var ses = 1.0
func aggiorna_risonanza(delta):
	t += delta
	if t > 3.0:
		t = 0.0
		i_wav = 0
		if ses > 0.1:
			ses = 0.0
			print("sons")
		else:
			ses = 1.0
			print("sens")
	
	for i in range(passaggi_tubo.size()):
		
		
		if i == 0:
			passaggi_tubo[i].calcola_pressione_nuova(delta,null,passaggi_tubo[i+1],(sin(t*880*4)+sin(t*880* 2)) * ses)
		elif i == passaggi_tubo.size()-1:
			passaggi_tubo[i].calcola_pressione_nuova(delta,passaggi_tubo[i-1],null)
		else:
			passaggi_tubo[i].calcola_pressione_nuova(delta,passaggi_tubo[i-1],passaggi_tubo[i+1])
	
	buffer.call_deferred("aggiungi_campione_fisico",passaggi_tubo[4].pressione_attuale*200, delta)

func _physics_process(delta):
	for i in range(passaggi_tubo.size()) :
		get_child(i).valore_forzato = passaggi_tubo[i].pressione_attuale*200


var i_wav := 0

func read_16bit_sample(stream: AudioStreamWAV, reset := false) -> float:
	assert(stream.format == AudioStreamWAV.FORMAT_16_BITS)
	if reset:
		i_wav = 0
	
	var bytes = stream.data
	# Read by packs of 2 bytes
	
	var b0 = bytes[i_wav]
	var b1 = bytes[i_wav + 1]
	# Combine low bits and high bits to obtain 16-bit value
	var u = b0 | (b1 << 8)
	# Emulate signed to unsigned 16-bit conversion
	u = (u + 32768) & 0xffff
	# Convert to -1..1 range
	var s = float(u - 32768) / 32768.0
	
	
	i_wav += 96
	
	return s
