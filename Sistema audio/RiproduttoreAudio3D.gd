extends AudioStreamPlayer3D
class_name RiproduttoreAudio3D

@export var componente_audio_precedente : ComponenteAudio
@export_range(0.0,2.0) var qnt_dc_offset := 0.9
var dc_offset_continuo := 0.0
var dc_offset := 0.1
var vel_agg_dc_offset := 0.0
@export_range(1,8000) var lentezza_aggiornamento_dc_offset := 100 :
	set(val):
		lentezza_aggiornamento_dc_offset = val
		vel_agg_dc_offset = 1.0 / lentezza_aggiornamento_dc_offset as float
	get:
		return lentezza_aggiornamento_dc_offset


var playback : AudioStreamGeneratorPlayback

func _ready():
	stream = AudioStreamGenerator.new()
	stream.mix_rate = InfoAudio.frequenza_campionamento_hz
	stream.buffer_length = 0.1
	play()
	playback = get_stream_playback()
	
	_elabora_frame_audio()


func _physics_process(delta):
	if !playing:
		play()
		print("/!\\AUDIO BLOCCATO/!\\")
	_elabora_frame_audio()

var count : int = 0
func _elabora_frame_audio():
	var frame_rimanenti := playback.get_frames_available()
	while frame_rimanenti > 0:
		var val = componente_audio_precedente.sample_audio()
		
		dc_offset_continuo += val*vel_agg_dc_offset
		count += 1
		if count > lentezza_aggiornamento_dc_offset:
			dc_offset = dc_offset_continuo
			dc_offset_continuo = 0
			count = 0
		
		val -= (dc_offset * 0.5)*qnt_dc_offset
		
		if is_nan(val) : print("/!\\VALORE NAN RESTITUITO/!\\")
		playback.push_frame(Vector2.ONE * val)
		frame_rimanenti -= 1
