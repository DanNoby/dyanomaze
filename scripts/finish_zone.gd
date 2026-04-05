extends Area3D

func _ready():
	$SwitchAudio.play()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		$SwitchAudio.play()
		if body.has_method("win"):
			body.win()
		GameManager.emit_signal("level_complete")
