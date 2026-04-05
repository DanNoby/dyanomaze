extends Area3D

@export var lifespan: float = 8.0 # How long it stays on the map

func _ready():
	# Make it bob up and down
	var float_tween = create_tween().set_loops()
	float_tween.tween_property($mug_full2, "position:y", 0.5, 1.0).as_relative()
	float_tween.tween_property($mug_full2, "position:y", -0.5, 1.0).as_relative()
	
	# Make it spin
	var spin_tween = create_tween().set_loops()
	spin_tween.tween_property($mug_full2, "rotation:y", deg_to_rad(360), 2.0).as_relative()

	# Start the self-destruct sequence
	despawn_routine()

func despawn_routine():
	# Wait for most of its lifespan
	await get_tree().create_timer(lifespan - 1.5).timeout
	
	# If the player hasn't picked it up yet, shrink it out of existence smoothly
	if is_instance_valid($mug_full2):
		var shrink_tween = create_tween()
		shrink_tween.tween_property($mug_full2, "scale", Vector3.ZERO, 1.5)
		
		await shrink_tween.finished
		queue_free()

# Detect Player
func _on_body_entered(body):
	# Bulletproof check for the player (handles uppercase, lowercase, and node name)
	if body.is_in_group("Player") or body.is_in_group("player") or body.name == "Player":
		GameManager.heal(1) # Heal
		
		queue_free()
		get_tree().call_group("ScoreUI", "add_score", 5, true, Color(0,1,0))
