extends AudioStreamPlayer

var playback : AudioStreamGeneratorPlayback
@export var buffer_audio : BufferFisicaAudio


func _ready():
	stream = AudioStreamGenerator.new()
	play()
	playback = get_stream_playback()


func riempi_buffer():
	for i in range(playback.get_frames_available()):
		playback.push_frame(Vector2.ONE * buffer_audio.leggi_buffer())


func _process(delta):
	riempi_buffer()
