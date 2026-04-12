extends Area3D

var target = null
var speed = 2.5    # Adjusted speed
var flying_height = 2.5 # Height of flight
var is_launching = true # State to prevent moving while popping up
var death_particles = preload("res://scenes/death_particles.tscn") # Adjust path if needed

var time_passed: float = 0.0
@export var wave_frequency: float = 2.0 # How fast it weaves
@export var wave_amplitude: float = 2 # How wide it weaves
@export var noise_intensity: float = 0.9 # How much random jitter it has

func _ready():
	target = get_tree().get_first_node_in_group("player")
	
	# Launch
	position.y = 0.5 
	
	# pop up
	var tween = create_tween()
	
	# Animating to flying_height over 0.5 seconds with a "Bouncy" effect
	tween.tween_property(self, "position:y", flying_height, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	is_launching = false
	
	# Safety kill timer
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _process(delta):
	if is_launching or not target:
		return

	# Track time for the sine wave
	time_passed += delta

	# 1. Get the base forward direction
	var destination = target.global_position
	destination.y = flying_height 
	var forward_dir = (destination - global_position).normalized()

	# 2. Find the perpendicular axis (Left/Right)
	var right_dir = forward_dir.cross(Vector3.UP).normalized()

	# 3. Calculate the smooth wave and the chaotic noise
	var main_wave = sin(time_passed * wave_frequency) * wave_amplitude
	var noise_wave = sin(time_passed * wave_frequency * 3.7) * noise_intensity

	# 4. Combine them and alter the movement direction
	var wobble_offset = right_dir * (main_wave + noise_wave)
	var final_dir = (forward_dir + wobble_offset).normalized()

	# 5. Move and rotate
	global_position += final_dir * speed * delta
	look_at(target.global_position, Vector3.UP)

# Collisions
func die():
	var chunks = death_particles.instantiate()
	get_tree().current_scene.add_child(chunks)
	
	chunks.global_position = global_position
	queue_free()

func _on_body_entered(body):
	if body.name == "Player": 
		if body.has_method("hit"):
			body.hit()
		queue_free()
