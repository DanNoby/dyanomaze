extends Area3D

var target = null
var speed = 1.5    # Adjusted speed
var flying_height = 2.5 # Height of flight
var is_launching = true # State to prevent moving while popping up
var death_particles = preload("res://scenes/death_particles.tscn") # Adjust path if needed

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
	# If we are currently launching or have no target, don't move
	if is_launching or not target:
		return
		
	# Chasing
	var destination = target.global_position
	destination.y = flying_height 
	
	var direction = (destination - global_position).normalized()
	global_position += direction * speed * delta
	
	look_at(target.global_position, Vector3.UP)

# Collisions
func die():
	var chunks = death_particles.instantiate()
	get_tree().current_scene.add_child(chunks)
	
	# 2. Move chunks to the enemy's exact position before it dies
	chunks.global_position = global_position
	queue_free()

func _on_body_entered(body):
	if body.name == "Player": 
		if body.has_method("hit"):
			body.hit()
		queue_free()
