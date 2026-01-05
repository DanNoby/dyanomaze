extends Area3D

var target = null
var speed = 0    # Adjusted speed
var flying_height = 2.5 # Height to fly OVER walls (standard walls are usually 2.0 high)
var is_launching = true # State to prevent moving while popping up

func _ready():
	target = get_tree().get_first_node_in_group("player")
	
	# --- THE LAUNCH EFFECT ---
	# 1. Start slightly inside the floor
	position.y = 0.5 
	
	# 2. Create a Tween to animate the "Pop Up"
	var tween = create_tween()
	
	# Animate Y to flying_height over 0.5 seconds with a "Bouncy" effect
	tween.tween_property(self, "position:y", flying_height, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 3. Wait for animation to finish before chasing
	await tween.finished
	is_launching = false
	
	# Safety kill timer
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _process(delta):
	# If we are currently launching or have no target, don't move
	if is_launching or not target:
		return
		
	# --- CHASE LOGIC ---
	
	# 1. Where do we want to go?
	# We want the Player's X and Z, but NOT their Y (we want to stay flying high)
	var destination = target.global_position
	destination.y = flying_height 
	
	# 2. Calculate direction
	var direction = (destination - global_position).normalized()
	
	# 3. Move
	global_position += direction * speed * delta
	
	# 4. Look at Player (Visuals)
	# We look at the actual player position so the worm angles down menacingly
	look_at(target.global_position, Vector3.UP)
	#rotate_y(deg_to_rad(180))

# --- COLLISIONS ---
func die():
	queue_free()

func _on_body_entered(body):
	if body.name == "Player": 
		if body.has_method("hit"):
			body.hit()
		queue_free()
