extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		print("WIN!")
		# This is the line your debugger was missing!
		GameManager.emit_signal("level_complete")
