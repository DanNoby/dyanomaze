extends GPUParticles3D

func _ready():
	$enemydeath.pitch_scale = randf_range(0.8, 1.2)
	emitting = true
	
	await finished
	queue_free()
