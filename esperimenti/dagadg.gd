extends Node3D



func _ready():
	var nuova_grandezza := 3
	var arr := [1,2,3,4,5,6,7,8]
	print(arr)
	
	
	
	var passo := (nuova_grandezza-1) as float / (arr.size()-1) as float
	var nuovo_buffer : Array[float]
	nuovo_buffer.resize(nuova_grandezza)
	nuovo_buffer.fill(0.0)

	if nuova_grandezza > arr.size() :
		for i in range(nuova_grandezza):
			var flr := clampi(floori(i / passo), 0, arr.size()-1)
			var cel := clampi(ceili( i / passo), 0, arr.size()-1)
			print(flr)
			
			nuovo_buffer[i] = lerpf(arr[flr],arr[cel], i/passo - flr)
	else :
		var div : Array[float]
		div.resize(nuova_grandezza)
		div.fill(0.0)
		for i in range(arr.size()):
			var flr := clampi(floori(i * passo), 0, arr.size()-1)
			var cel := clampi(ceili( i * passo), 0, arr.size()-1)
			print(flr)
			
			nuovo_buffer[flr] += arr[i] * maxf(i*passo - flr, 0.0)
			nuovo_buffer[cel] += arr[i] * maxf(cel - i*passo, 0.0)
			
			div[flr] += maxf(i*passo - flr, 0.0)
			div[cel] += maxf(cel - i*passo, 0.0)
		
		for i in range(nuova_grandezza) :
			nuovo_buffer[i] /= div[i]


	arr = nuovo_buffer
	
	print(arr)
