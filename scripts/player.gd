extends CharacterBody3D

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.003

# --- MODES ---
var is_fps_mode = false
var is_invincible = false
var is_attacking = false

# --- NODES ---
@onready var mesh = $Knight
@onready var sword_container = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D/sword
@onready var sword_hitbox = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D/sword/swordhitbox
@onready var anim = $Knight/AnimationPlayer

# FPS Setup nodes
@onready var skeleton = $Knight/Rig_Medium/Skeleton3D
@onready var head = $Head
@onready var camera_fps = $Head/CameraFPS
@onready var camera_tps = $CameraTPS 

# --- SWORD CONFIGURATION (Tweak these in Inspector while playing!) ---
@export var fps_sword_offset = Vector3(0, 0.5, 0.5)  
@export var fps_sword_rotation = Vector3(45, 0, 0)
@export var tps_sword_rot = Vector3.ZERO
var tps_sword_pos = Vector3.ZERO 

func _ready():
	# Store the original position so we can reset it later
	if sword_container:
		tps_sword_pos = sword_container.position
	else:
		print("ERROR: Sword Container not found! Check path.")
		
	update_camera_mode()

func _input(event):
	if is_fps_mode and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(event.relative.y * MOUSE_SENSITIVITY) # Removed negative sign (Fixes Inverted Look)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if Input.is_action_just_pressed("change_view"): 
		toggle_view_mode()

	# Escape to free mouse
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Click to recapture mouse (Only if alive!)
	if Input.is_action_just_pressed("ui_accept"): 
		if is_fps_mode and GameManager.current_hearts > 0: 
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# --- 1. FORCE SWORD POSITION (The "Live Tuner") ---
	# We do this every frame to override the AnimationPlayer
	if is_fps_mode and sword_container:
		sword_container.position = tps_sword_pos + fps_sword_offset
		sword_container.rotation_degrees = fps_sword_rotation
	elif not is_fps_mode and sword_container:
		sword_container.position = tps_sword_pos
		sword_container.rotation = tps_sword_rot
		
	# --- ATTACK INPUT ---
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or not is_fps_mode:
			attack()
	
	# --- MOVEMENT ---
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3.ZERO
	
	if is_fps_mode:
		# FPS Movement: Relative to camera
		var raw_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		direction = -raw_dir # Negative because your model/camera likely faces -Z
	else:
		# Top Down Movement: Absolute directions
		direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotate Visuals (Only in Top-Down)
		if not is_fps_mode and mesh:
			var target_spot = global_position + direction
			mesh.look_at(target_spot, Vector3.UP)
			mesh.rotate_y(deg_to_rad(180)) 
		
		if not is_attacking:
			if anim.current_animation != "Running_A": anim.play("Running_A", 0.3)
				
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if not is_attacking:
			if anim.current_animation != "Idle_B": anim.play("Idle_B", 0.3)

	move_and_slide()
	
	if global_position.y < -5.0:
		die_instant()

# --- CAMERA HELPERS ---
func toggle_view_mode():
	if not is_fps_mode: 
		# Entering FPS: Snap Body to match where Mesh was looking
		rotation.y = mesh.rotation.y
		mesh.rotation.y = deg_to_rad(0) # Reset mesh to face forward relative to root
		
	is_fps_mode = not is_fps_mode
	update_camera_mode()

func update_camera_mode():
	if is_fps_mode:
		# FPS MODE
		if camera_tps: camera_tps.current = false
		if camera_fps: camera_fps.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		toggle_body_parts(false) 
	else:
		# TPS MODE
		if camera_fps: camera_fps.current = false
		if camera_tps: camera_tps.current = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		toggle_body_parts(true)

# --- VISIBILITY LOOPER ---
func toggle_body_parts(show_full_body: bool):
	if not skeleton: return
	for child in skeleton.get_children():
		if child is BoneAttachment3D: continue 
		
		if child is MeshInstance3D:
			if show_full_body:
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				child.visible = true
			else:
				# FPS Mode: Hide Head Only
				if "Head" in child.name or "Helmet" in child.name:
					child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				else:
					child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
					child.visible = true

# --- ATTACK ---
func attack():
	is_attacking = true
	anim.play("Interact") 
	sword_hitbox.monitoring = true 
	await get_tree().create_timer(0.4).timeout
	sword_hitbox.monitoring = false
	is_attacking = false

# --- HEALTH/DEATH ---
func hit():
	if is_invincible: return
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

func win():
	set_physics_process(false) 
	set_process_input(false) # Stops the _input function from snatching the mouse back
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func die():
	set_physics_process(false)
	is_invincible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
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

func _on_swordhitbox_area_entered(area: Area3D) -> void:
	if area == self: return 
	if area.is_in_group("enemy"):
		if area.has_method("die"):
			area.die()
