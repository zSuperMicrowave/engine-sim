extends ComponenteAudio
class_name Valve

@export var previous_component : ComponenteAudio
@export var cam_profile := Curve.new()
@export var noise_amount := 1.0
@export var noise_attenuation := 8000.0

var turbidity := 0.0
var previous_valve_pos := 0.0
var valve_pos := 0.0
var pressure := 0.0

func set_pressure(pressure : float):
	self.pressure = pressure

func set_valve_position(camshaft_rotation : float):
	valve_pos =\
		cam_profile.sample_baked(
			fposmod(camshaft_rotation,TAU*2) / TAU*2.0 )

func sample_audio():
	var ratio := 44100.0 / float(InfoAudio.frequenza_campionamento_hz)
	turbidity += max((valve_pos - previous_valve_pos) * ratio,0.0) * pressure * noise_amount
	turbidity = lerpf(turbidity, 0.0, clampf(noise_attenuation/ratio,0.0,1.0))
	previous_valve_pos = valve_pos
	
	return previous_component.sample_audio() * valve_pos + (randf() * turbidity)
