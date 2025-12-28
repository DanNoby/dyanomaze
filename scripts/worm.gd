extends Area3D

var target = null
var speed = 2.0 # Adjust this if they are too fast/slow

func _ready():
	# Find the player automatically
	target = get_tree().get_first_node_in_group("player")
	
	# Safety Timer: Kill worm after 10 seconds so they don't pile up forever
	await get_tree().create_timer(10.0).timeout
	queue_free()

func _process(delta):
	if target:
		# 1. CALCULATE DIRECTION
		# We want it to fly at the player, but maybe keep Y level so it doesn't dig into the floor
		var target_pos = target.global_position
		target_pos.y += 1.0 # Aim for the player's chest/head
		
		var direction = (target_pos - global_position).normalized()
		
		# 2. MOVE
		global_position += direction * speed * delta
		
		# 3. LOOK AT PLAYER
		look_at(target_pos, Vector3.UP)

# --- DEATH FUNCTION (Called by Sword) ---
func die():
	# OPTIONAL: Add a particle effect here later!
	queue_free() # Poof! Gone.

# --- ATTACK FUNCTION (Touches Player Body) ---
# Connect the "body_entered" signal of the Worm Area3D to this function!
func _on_body_entered(body):
	if body.name == "Player": # Or use groups: if body.is_in_group("player"):
		# If the player has a 'hit' function, call it
		if body.has_method("hit"):
			body.hit()
		queue_free() # Worm dies on impact
