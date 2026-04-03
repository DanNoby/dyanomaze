extends GPUParticles3D

func _ready():
	emitting = true
	# Deletes this node from the game exactly when the particles finish
	await finished
	queue_free()
