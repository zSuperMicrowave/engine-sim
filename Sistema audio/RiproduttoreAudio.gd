extends AudioStreamPlayer
class_name RiproduttoreAudio

@export var componente_audio_precedente : ComponenteAudio
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
		playback.push_frame(Vector2.ONE * val)
		frame_rimanenti -= 1
