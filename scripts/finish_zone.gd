extends Area3D

func _ready():
	# Connect the "body_entered" signal via code (shortcut method!)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		print("YOU WIN!")
		# For now, let's just quit or reload. 
		# Later, we will show a "You Win" menu.
		call_deferred("change_scene")

func change_scene():
	# If you have a Main Menu, go there. For now, just restart.
	get_tree().reload_current_scene()	
