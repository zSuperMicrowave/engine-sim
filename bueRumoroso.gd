extends AudioStreamPlayer
@export var audio : AudioStreamWAV
@export_range(2,8000) var am_hz : int
@export_range(0.0,100.0) var am_effect : float
@export_range(0.0,1.0) var low_boost : float
var samples : Array = []
var current_sample := 0

var last_sample := 0.0

var playback : AudioStreamGeneratorPlayback

func _enter_tree():
	convert_audio_to_mono_samples()

func _ready():
	stream = AudioStreamGenerator.new()
	stream.mix_rate = audio.mix_rate
	stream.buffer_length = 0.1
	play()
	playback = get_stream_playback()
	
	_elabora_frame_audio()


func _physics_process(delta):
	if !playing:
		play()
		playback = get_stream_playback()
		print("/!\\AUDIO BLOCCATO/!\\")
	
	_elabora_frame_audio()


func _elabora_frame_audio():
	var frame_rimanenti := playback.get_frames_available()
	
	while frame_rimanenti > 0:
		if samples.is_empty() :
			playback.push_frame(Vector2.ZERO)
			continue
		
		var sample = samples[current_sample]
		
		# Ottieni il passabasso
		last_sample = lerpf(last_sample, sample, 1.0/(float(stream.mix_rate)/float(am_hz)))
		
		#sample -= last_sample
		
		# Filtro am
		sample /= 2.0 + last_sample * am_effect
		
		# Reintegra bassi
		sample += last_sample * low_boost
		
		playback.push_frame(Vector2.ONE * sample)
		
		
		current_sample += 1
		if current_sample >= samples.size() : current_sample = 0
		frame_rimanenti -= 1


func convert_audio_to_mono_samples():
	var bytes = audio.data
	for i in range(bytes.size() * 0.25) :
		var t = i*2
		var b0 = bytes[t]
		var b1 = bytes[t + 1]
		# Combine low bits and high bits to obtain 16-bit value
		var u = b0 | (b1 << 8)
		# Emulate signed to unsigned 16-bit conversion
		u = (u + 32768) & 0xffff
		# Convert to -1..1 range
		var s = float(u - 32768) / 32768.0
		samples.append(s)

