extends Object
class_name AudioSynchronizerBuffer

var buffer : RingBuffer = null

func _init(buffer_length):
	var arr := Array()
	for i in range(buffer_length * 0.5) :
		arr.push_back(0.0)
	
	buffer = RingBuffer.new(buffer_length,arr)


var avg_buffer_size := 0
var count_avg_samps := 0
var correction_delta := 1.0
func process_correction(size_correction_amount):
	if count_avg_samps == 0 or avg_buffer_size == 0 :
		correction_delta = 1.0
		return
	
	var half := float(buffer.max_size() * 0.5)
	var avg := float(avg_buffer_size) / float(count_avg_samps)
	var temp_correction_delta = half / avg
#	print("Avg: ",avg)
#	print("Current length: ", buffer.size())
#	print("Correction delta: ",temp_correction_delta)
	correction_delta = lerpf(1.0,temp_correction_delta,size_correction_amount)
#	print("Final correction: ",correction_delta)
	
	avg_buffer_size = 0
	count_avg_samps = 0


func sample(fail_return_value := 0.0) -> float:
	avg_buffer_size += buffer.size()
	count_avg_samps += 1
	
	var out = buffer.pop_front()
	if out == null : return 0.0
	return out


var remainder := 0.0
#var delta_time := Time.get_ticks_usec()
func send_value(val : float,delta : float):
	#var delta = float(Time.get_ticks_usec() - delta_time) / 1_000_000.0
	delta *= correction_delta
	#delta_time = Time.get_ticks_usec()
	
	var sample_width : float = delta * InfoAudio.frequenza_campionamento_hz
	var full_sample_width : int = ceili(sample_width)
	
	
	for i in range(full_sample_width) :
		var f1 = ceilf(i)/sample_width - (full_sample_width-sample_width)/sample_width
		var f2 = floorf(i)/sample_width - (full_sample_width-sample_width)/sample_width
		f1 = clampf(f1,0.0,1.0)
		f2 = clampf(f2,0.0,1.0)
		var f = (f1+f2)*0.5
	
		buffer.set_back(full_sample_width-i,
			lerpf(
				buffer.get_back(full_sample_width-i),
				val,
				f)
			)
	
	for i in range(floori(sample_width)) :
		buffer.push_back(val)
	
	var extra_steps := 0
	remainder += sample_width - floorf(sample_width)
	while remainder >= 1.0 :
		remainder -= 1.0
		extra_steps += 1
	
	for extra in range(extra_steps) :
		buffer.push_back(val)
