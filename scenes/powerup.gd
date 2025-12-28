extends Area3D

enum Type { HEALTH, IMMUNITY }
var my_type = Type.HEALTH

func _ready():
	# Randomly decide type (80% Health, 20% Immunity)
	if randf() > 0.8:
		my_type = Type.IMMUNITY
		# Change color to Blue/Gold
	else:
		# Change color to Red
		pass

func _on_body_entered(body):
	if body.name == "Player":
		if my_type == Type.HEALTH:
			GameManager.heal_player() # You'll need to add this to Manager
		else:
			body.activate_super_immunity() # You'll need to add this to Player
		queue_free()
