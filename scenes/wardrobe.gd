extends CharacterBody3D

const SPEED = 5.0
var is_invincible = false
var is_attacking = false

# Hardcoded references (The "Old Reliable" way)
@onready var mesh = $Knight
@onready var sword_hitbox = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D/sword/swordhitbox
@onready var anim = $Knight/AnimationPlayer

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# --- ATTACK INPUT ---
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		attack()
	
	# --- MOVEMENT ---
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		# 1. MOVE
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# 2. ROTATE (Visuals)
		var target_spot = global_position + direction
		if mesh:
			mesh.look_at(target_spot, Vector3.UP)
			mesh.rotate_y(deg_to_rad(180)) 
		
		# 3. ANIMATION
		if not is_attacking:
			if anim.current_animation != "Running_A":
				anim.play("Running_A")
				
	else:
		# Stop moving smoothly
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if not is_attacking:
			if anim.current_animation != "Idle_B":
				anim.play("Idle_B")

	move_and_slide()
	
	# Void check
	if global_position.y < -5.0:
		die_instant()

# --- ATTACK LOGIC ---
func attack():
	is_attacking = true
	
	# Play the animation
	anim.play("Interact") 
	
	# 1. Wind up
	await get_tree().create_timer(0.1).timeout
	
	# 2. SWING START
	sword_hitbox.monitoring = true
	
	# 3. SWING DURATION
	await get_tree().create_timer(0.3).timeout
	
	# 4. SWING END
	sword_hitbox.monitoring = false
	is_attacking = false

# --- SIGNALS ---
func _on_sword_hitbox_area_entered(area):
	if area == self: return # Safety check
	
	if area.is_in_group("enemy"):
		print("Sword hit: " + area.name)
		if area.has_method("die"):
			area.die()

# --- HEALTH/DEATH LOGIC ---
func hit():
	if is_invincible:
		return
	
	GameManager.take_damage()
	
	if GameManager.current_hearts <= 0:
		die()
	else:
		flash_damage()

func flash_damage():
	is_invincible = true
	for i in range(5):
		if mesh: mesh.visible = not mesh.visible
		await get_tree().create_timer(0.1).timeout
	if mesh: mesh.visible = true
	is_invincible = false

func die():
	set_physics_process(false)
	is_invincible = true
	if mesh: mesh.visible = true
	
	velocity = Vector3.ZERO 
	
	anim.stop()
	anim.play("Death_A")
	
	await anim.animation_finished
	GameManager.emit_signal("game_over")

func die_instant():
	GameManager.current_hearts = 0
	GameManager.emit_signal("health_changed", 0)
	die()
