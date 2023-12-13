extends CharacterBody3D


@export var velocita := 5.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):
	if Input.is_action_just_pressed("esc") :
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Prendi i 3 assi di movimento in input
	var input_x := Input.get_axis("sinistra", "destra")
	var input_y := Input.get_axis("sotto", "sopra")
	var input_z := Input.get_axis("avanti", "indietro")
	
	# Assegnali alla direzione del personaggio
	var direzione := (transform.basis * Vector3(input_x, input_y, input_z).normalized())

	velocity.x = direzione.x * velocita
	velocity.y = direzione.y * velocita
	velocity.z = direzione.z * velocita

	move_and_slide()


func _input(event):
	if event is InputEventMouseMotion :
		rotate_y(event.relative.x * -0.0045)
		$telecamera.rotate_x(event.relative.y * -0.0045)
