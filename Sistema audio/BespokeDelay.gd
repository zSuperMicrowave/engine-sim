extends ComponenteAudio
class_name BespokeDelay

var buffer : Array[float]
var buffer_pointer := 0

@export var campionatore : CampionatorePistone
@export_range(4,4000) var buffer_len := 5
@export var feedback := 0.8
@export var do_input := true
@export var invert := true
@export var single_delay := false
@export_range(0.01,10) var delay_length_multiplier := 1.0
@export_range(0.01,2.0) var gain := 1.0


func _enter_tree():
	buffer.resize(buffer_len)


func ottieni_campione() -> float:
	var ratio = 44100 / InfoAudio.frequenza_campionamento_hz
	buffer_pointer += 1
	
	var delay_samps : float = campionatore.ottieni_riverbero() * delay_length_multiplier
	delay_samps = clampf(delay_samps * ratio, 0.01, buffer_len-2)
	
	var samps_ago_a : int = int(delay_samps+1)
	var samps_ago_b : int = samps_ago_a - 1;

	var sample : float = read_buffer(-samps_ago_a)
	var next_sample : float = read_buffer(-samps_ago_b)
	var a : float = delay_samps+1 - samps_ago_a
	var delayed_sample := lerpf(sample, next_sample, a)

	var input : float = campionatore.ottieni_campione()
	
	if do_input and not single_delay :
		write_buffer(0,input)
	
	var delay_input = delayed_sample * feedback * (-1 if invert else 1)
	add_to_buffer(0, delay_input)
	
	if do_input and single_delay :
		write_buffer(0,input)

	var out := read_buffer(0) * gain
	
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
