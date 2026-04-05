extends GPUParticles3D

func _ready():
	$enemydeath.pitch_scale = randf_range(0.8, 1.2)
	emitting = true
	# Deletes this node from the game exactly when the particles finish
	await finished
	queue_free()
