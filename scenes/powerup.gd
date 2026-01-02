extends Area3D

# Visual Float Animation
func _ready():
	# Make it bob up and down and spin
	var tween = create_tween().set_loops()
	
	tween.tween_property($mug_full2, "position:y", 0.5, 1.0).as_relative()
	tween.tween_property($mug_full2, "position:y", -0.5, 1.0).as_relative()
	
	var spin_tween = create_tween().set_loops()
	spin_tween.tween_property($mug_full2, "rotation:y", deg_to_rad(360), 2.0).as_relative()

# Detect Player
func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		# 1. Heal
		GameManager.heal(1)
		
		# 2. Delete the mug
		queue_free()
