extends Node
class_name RingBuffer

var buffer := Array()
var front_pointer := 0
var back_pointer := 0
var current_size := 0



func _init(max_size : int, arr : Array = []):
	if max_size < 2 :
		push_error("WARNING, RingBuffer requires max_size >= 2")
		max_size = 2
	buffer.resize(max_size)
	var half : int = max_size/2
	front_pointer = half - 1
	back_pointer = half
	
	for e in arr:
		push_back(e)


func push_back(value):
	if current_size >= max_size() :
		push_warning("Can't push back, buffer is full.")
		return
	
	buffer[back_pointer] = value
	back_pointer = (back_pointer+1) % buffer.size()
	current_size += 1


func push_front(value):
	if current_size >= max_size() :
		push_warning("Can't push front, buffer is full.")
		return
	
	buffer[front_pointer] = value
	front_pointer = (front_pointer-1) % buffer.size()
	current_size += 1


func pop_back():
	if current_size <= 0 :
		push_warning("Can't pop back, buffer is empty.")
		return null
	
	var out = buffer[back_pointer]
	back_pointer = (back_pointer-1) % buffer.size()
	current_size -= 1
	return out


func pop_front():
	if current_size <= 0 :
		push_warning("Can't pop front, buffer is empty.")
		return null
	
	var out = buffer[front_pointer]
	front_pointer = (front_pointer+1) % buffer.size()
	current_size -= 1
	return out


func max_size():
	return buffer.size()


func size():
	return current_size
