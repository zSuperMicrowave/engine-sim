extends AudioStreamPlayer3D
class_name RiproduttoreAudio3D

@export var componente_audio_precedente : ComponenteAudio
@export_range(2,8000) var dc_offset_hz : int
var dc_offset := 0.0

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


func _elabora_frame_audio():
	var frame_rimanenti := playback.get_frames_available()
	while frame_rimanenti > 0:
		var val = componente_audio_precedente.sample_audio()
		
		var d := float(dc_offset_hz) / float(InfoAudio.frequenza_campionamento_hz)
		dc_offset = lerpf(dc_offset,val,d)
		val -= dc_offset * 0.5
		
		if is_nan(val) : print("/!\\VALORE NAN RESTITUITO/!\\")
		playback.push_frame(Vector2.ONE * val)
		frame_rimanenti -= 1
