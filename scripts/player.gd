extends CharacterBody3D

const SPEED = 5.0
var is_invincible = false
@onready var mesh = $Knight
@onready var anim = $Knight/AnimationPlayer

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 1. INPUT
	# Standard movement relative to the screen (North is Up)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		# 2. MOVE (The invisible capsule)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# 3. ROTATE (The Mage Visuals ONLY)
		# We calculate where we want to look
		var target_spot = global_position + direction
		
		# We tell the MAGE (mesh) to look there, NOT the player (self)
		if mesh:
			mesh.look_at(target_spot, Vector3.UP)
			mesh.rotate_y(deg_to_rad(180))
		
		if anim.current_animation != "Running_A":
			anim.play("Running_A")
			
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if anim.current_animation != "Idle_B":
			anim.play("Idle_B")

	move_and_slide()
	
	# Void check
	if global_position.y < -5.0:
		die_instant()

func hit():
	if is_invincible:
		return
	
	# 1. Take damage
	GameManager.take_damage()
	
	# 2. CHECK: Did we just die?
	if GameManager.current_hearts <= 0:
		die() # Call our new custom death function
	else:
		# If we are still alive, do the flash effect
		flash_damage()

func flash_damage():
	is_invincible = true
	# Toggle visibility 5 times fast
	for i in range(5):
		if mesh: mesh.visible = not mesh.visible
		await get_tree().create_timer(0.1).timeout
	if mesh: mesh.visible = true
	is_invincible = false

# Consolidate ALL death (Traps AND Void) here
func die():
	# 1. Stop everything
	set_physics_process(false)
	is_invincible = true # Prevent getting hit again while dying
	if mesh: mesh.visible = true # Force visible in case we were flashing
	
	# 2. Stop movement (prevent falling forever)
	velocity = Vector3.ZERO 
	
	# 3. Play Animation
	# Stop any running animations first to be safe
	anim.stop()
	anim.play("Death_A")
	
	# 4. Wait for it to finish
	await anim.animation_finished
	
	# 5. NOW we trigger the screen
	GameManager.emit_signal("game_over")

# Update the void check to use this new function too
func die_instant():
	GameManager.current_hearts = 0
	GameManager.emit_signal("health_changed", 0)
	die()
