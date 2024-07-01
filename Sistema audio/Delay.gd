extends ComponenteAudio
class_name Delay

var buffer : Array[float]
var buffer_pointer := 0

@export var previous_component : ComponenteAudio
@export_range(4,4000) var buffer_len := 5
@export_range(0.01,2.0) var gain := 1.0

@export_group("Delay prams")
@export_range(0.1,3998) var fixed_delay := 100.0
@onready var delay_samps := fixed_delay
@export var force_fixed_delay := false
@onready var can_vary_delay := previous_component is CampionatorePistone
@export_range(0.0,1.0) var feedback := 0.8
@export var invert_feedback := false

@export_group("Debug")
@export var monitor_params := false
@export_range(0.01,10) var delay_length_multiplier := 1.0
@export var straight_trough := false

@onready var samp_rate_ratio = 44100 / InfoAudio.frequenza_campionamento_hz

var debug_min_delay := 999999999.9
var debug_max_delay := 0.0


func _enter_tree():
	buffer.resize(buffer_len)


func _physics_process(delta):
	_update_params()
	
	if monitor_params :
		_debug()


func _update_params():
	samp_rate_ratio = 44100 / InfoAudio.frequenza_campionamento_hz
	
	if buffer_len != buffer.size() :
		buffer.resize(buffer_len)
	
	if force_fixed_delay :
		delay_samps = fixed_delay 
	
	can_vary_delay =\
		previous_component is CampionatorePistone


func _debug():
	print("Min delay: ", debug_min_delay)
	print("Max delay: ", debug_max_delay)
	print("Current delay: ",delay_samps)


func sample_audio(samps : int) -> Array[float]:
	if is_zero_approx(feedback) or straight_trough:
		return previous_component.sample_audio(samps)

	# Samples retrieving (DO NOT REPEAT!)
	var samp_buf := previous_component.sample_audio(samps)
	var rev_buf : Array[float] = []
	if not force_fixed_delay and can_vary_delay : 
		rev_buf = previous_component.sample_reverb(samps)

	var out : Array[float] = []

	# Apply filter on samples
	for i in range(samps) :
		buffer_pointer = (buffer_pointer+1) % buffer_len

		if not force_fixed_delay and can_vary_delay : delay_samps =\
			rev_buf[i] * delay_length_multiplier +1

		delay_samps = clampf(delay_samps * samp_rate_ratio, 0.1, buffer_len-2)
		var delay_samps_int := roundi(delay_samps)

		var sample : float = read_buffer(-delay_samps_int - 1)
		var next_sample : float = read_buffer(-delay_samps_int)
		var delayed_sample :=\
			lerpf(sample, next_sample, delay_samps - delay_samps_int)

		buffer[buffer_pointer] = samp_buf[i]
		buffer[buffer_pointer] +=\
			delayed_sample * feedback * (-1 if invert_feedback else 1)

		if monitor_params :
			debug_min_delay = min(debug_min_delay, delay_samps)
			debug_max_delay = max(debug_max_delay, delay_samps)

		out.append(buffer[buffer_pointer] * gain)

	return out


func read_buffer(offset : int) -> float:
	var i := posmod(buffer_pointer + offset, buffer_len)
	return buffer[i]

func write_buffer(offset : int, input : float):
	var i := posmod(buffer_pointer + offset, buffer_len)
	buffer[i] = input

func add_to_buffer(offset : int, input : float):
	var i := posmod(buffer_pointer + offset, buffer_len)
	buffer[i] += input
