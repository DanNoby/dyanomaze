extends CharacterBody3D

const SPEED = 5.0
var is_invincible = false
@onready var mesh = $MeshInstance3D # Ensure this matches your visual node name

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
	if global_position.y < -5.0:
		die_instant()

func hit():
	# 1. If we are already blinking, ignore the damage
	if is_invincible:
		return
	
	# 2. Tell the Manager to lose a heart
	GameManager.take_damage()
	
	# 3. Become invincible temporarily
	is_invincible = true
	if mesh:
		mesh.transparency = 0.5 # Make player see-through
	
	# 4. Wait 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	# 5. Reset
	is_invincible = false
	if mesh:
		mesh.transparency = 0.0
	
func die_instant():
	# 1. Stop processing movement so we don't trigger this 100 times
	set_physics_process(false)
	
	# 2. Tell GameManager to set hearts to 0 instantly
	# (We manually force the game over signal)
	GameManager.current_hearts = 0
	GameManager.emit_signal("health_changed", 0)
	GameManager.emit_signal("game_over")
