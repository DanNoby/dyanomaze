extends CharacterBody3D

const SPEED = 5.0

var is_fps_mode = false
var is_invincible = false
var is_attacking = false
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

@onready var mesh = $Knight
@onready var sword_container = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D/sword
@onready var sword_hitbox = $Knight/Rig_Medium/Skeleton3D/BoneAttachment3D/sword/swordhitbox
@onready var anim = $Knight/AnimationPlayer

@onready var skeleton = $Knight/Rig_Medium/Skeleton3D
@onready var head = $Head
@onready var camera_fps = $Head/CameraFPS
@onready var camera_tps = $CameraTPS 

@export var fps_sword_offset = Vector3(0, 0.5, 0.5)  
@export var fps_sword_rotation = Vector3(45, 0, 0)
@export var tps_sword_rot = Vector3.ZERO
var tps_sword_pos = Vector3.ZERO 

func _ready():
	tps_sword_pos = sword_container.position
	update_camera_mode()
	set_view_mode(GlobalSettings.prefer_fps)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if is_fps_mode and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * GlobalSettings.mouse_sens)
		head.rotate_x(event.relative.y * GlobalSettings.mouse_sens) 
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(delta):
	if shake_duration > 0:
		shake_duration -= delta
		var random_x = randf_range(-shake_intensity, shake_intensity)
		var random_y = randf_range(-shake_intensity, shake_intensity)
		
		if is_fps_mode and camera_fps:
			camera_fps.h_offset = random_x
			camera_fps.v_offset = random_y
		elif not is_fps_mode and camera_tps:
			camera_tps.h_offset = random_x
			camera_tps.v_offset = random_y
			
	elif shake_intensity > 0:
		shake_intensity = 0.0
		if camera_fps:
			camera_fps.h_offset = 0.0
			camera_fps.v_offset = 0.0
		if camera_tps:
			camera_tps.h_offset = 0.0
			camera_tps.v_offset = 0.0

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if is_fps_mode and sword_container:
		sword_container.position = tps_sword_pos + fps_sword_offset
		sword_container.rotation_degrees = fps_sword_rotation
	elif not is_fps_mode and sword_container:
		sword_container.position = tps_sword_pos
		sword_container.rotation = tps_sword_rot
		
	if Input.is_action_just_pressed("ui_accept") and not is_attacking:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or not is_fps_mode:
			attack()
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = Vector3.ZERO

	if is_fps_mode:
		direction = -(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		direction = Vector3(-input_dir.x, 0, -input_dir.y).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED  

		if not is_fps_mode and mesh:
			var target_spot = global_position + direction
			# Add a tiny offset to prevent look_at errors if direction is perfectly zeroed
			if global_position.distance_to(target_spot) > 0.001: 
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

func set_view_mode(wants_fps: bool):
	if is_fps_mode == wants_fps: return 

	if wants_fps:
		rotation.y = mesh.rotation.y
		mesh.rotation.y = 0
	else:
		mesh.rotation.y = rotation.y
		rotation.y = 0
	is_fps_mode = wants_fps
	update_camera_mode()

func update_camera_mode():
	if is_fps_mode:
		if camera_tps: camera_tps.current = false
		if camera_fps: camera_fps.current = true
		toggle_body_parts(false) 
	else:
		if camera_fps: camera_fps.current = false
		if camera_tps: camera_tps.current = true
		toggle_body_parts(true)

func toggle_body_parts(show_full_body: bool):
	if not skeleton: return
	for child in skeleton.get_children():
		if child is BoneAttachment3D: continue 
		
		if child is MeshInstance3D:
			if show_full_body:
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				child.visible = true
			else:
				if "Head" in child.name or "Helmet" in child.name:
					child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				else:
					child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
					child.visible = true

func attack():
	is_attacking = true
	anim.play("Interact") 
	sword_hitbox.monitoring = true 
	
	$SwordAudio.pitch_scale = randf_range(0.8, 1.2)
	$SwordAudio.play()
	
	await get_tree().create_timer(0.4).timeout
	sword_hitbox.monitoring = false
	is_attacking = false

func hit():
	if is_invincible: return
	GameManager.take_damage()
	$GettingHit.play()
	
	if GameManager.current_hearts <= 0:
		die()
	else:
		flash_damage()
		shake_camera(0.2, 0.2)

func shake_camera(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func flash_damage():
	is_invincible = true
	for i in range(5):
		if mesh: mesh.visible = not mesh.visible
		await get_tree().create_timer(0.1).timeout
	if mesh: mesh.visible = true
	is_invincible = false
	
func powerup_flash():
	if not mesh: 
		return
	
	$PowerupAudio.play()
	var flash_mat = StandardMaterial3D.new()
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.albedo_color = Color(1, 1, 1, 1) 
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1, 1, 1) 
	flash_mat.emission_energy_multiplier = 4.0 

	# 1. Paint the material on every mesh inside the Knight
	apply_flash_to_meshes(mesh, flash_mat)

	var tween = create_tween()
	tween.tween_property(flash_mat, "albedo_color:a", 0.0, 0.2)
	tween.parallel().tween_property(flash_mat, "emission_energy_multiplier", 0.0, 0.2)

	# 2. Strip the material off when the tween finishes
	tween.tween_callback(func(): remove_flash_from_meshes(mesh))

# --- HELPER FUNCTIONS ---ds

func apply_flash_to_meshes(node: Node, mat: Material):
	# If this specific piece is a mesh, paint it!
	if node is MeshInstance3D:
		node.material_overlay = mat
		
	# Keep digging deeper into the children
	for child in node.get_children():
		apply_flash_to_meshes(child, mat)

func remove_flash_from_meshes(node: Node):
	# If this specific piece is a mesh, clean it!
	if node is MeshInstance3D:
		node.material_overlay = null
		
	# Keep digging deeper into the children
	for child in node.get_children():
		remove_flash_from_meshes(child)

func win():
	set_physics_process(false) 
	set_process_input(false)
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

func trigger_hitstop():
	# Drop game speed to 5%
	Engine.time_scale = 0.2
	await get_tree().create_timer(0.3, true, false, true).timeout 
	Engine.time_scale = 1.0
	
func _on_swordhitbox_area_entered(area: Area3D) -> void:
	if area == self: return 
	if area.is_in_group("enemy"):
		if area.has_method("die"):
			area.die()
			shake_camera(0.1, 0.1)
			trigger_hitstop()
			
			get_tree().call_group("ScoreUI", "add_score", 10, true, Color(1,1,0))
