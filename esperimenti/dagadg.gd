extends Node3D

func _ready():
	var nuova_grandezza = 16
	var arr : Array[float] = [-8, 4, 6, 8]
	print(arr)
	print(ridimensiona_array(arr, nuova_grandezza))

func ridimensiona_array(arr : Array[float], nuova_grandezza : int) -> Array[float]:
	var passo = nuova_grandezza as float / arr.size()
	var nuovo_buffer : Array[float]
	nuovo_buffer.resize(nuova_grandezza)
	
	if nuova_grandezza > arr.size():
		for i in range(nuova_grandezza):
			var idx = i / passo
			var flr = int(idx) % arr.size()
			var cel = (flr + 1) % arr.size()
			var t = idx - flr
			nuovo_buffer[int(i+passo*0.45) % nuova_grandezza] = lerp(arr[flr], arr[cel], t)
	else:
		for i in range(nuova_grandezza):
			var start_idx = int(i * (arr.size() / nuova_grandezza))
			var end_idx = int((i + 1) * (arr.size() / nuova_grandezza))
			var sum = 0.0
			for j in range(start_idx, end_idx):
				sum += arr[j % arr.size()]
			nuovo_buffer[i] = sum / (end_idx - start_idx)

	return nuovo_buffer
