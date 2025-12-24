extends CharacterBody3D

const SPEED = 5.0

func _physics_process(delta):
	# Add gravity so the player stays on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction based on arrow keys or WASD
	# In 3D, "ui_up" (W) maps to negative Z (Forward)
	# "ui_down" (S) maps to positive Z (Backward)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# We maintain our Y velocity (gravity), but change X and Z
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# If no keys pressed, stop moving smoothly
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
