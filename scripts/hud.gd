extends CanvasLayer

@onready var message_screen = $MessageScreen
@onready var title_label = $MessageScreen/TitleLabel
@onready var health_label = $HealthLabel

func _ready():
	# Initial
	message_screen.visible = false
	
	update_heart_display(GameManager.current_hearts)
	
	# signals from the GameManager
	GameManager.health_changed.connect(update_heart_display)
	GameManager.game_over.connect(show_game_over)
	GameManager.level_complete.connect(show_win)

# Updates the text when we get hit
func update_heart_display(amount):
	var txt = " HP "
	for i in range(amount):
		txt += "♥ "
	health_label.text = txt

# When we run out of hearts
func show_game_over():
	title_label.text = "YOU DIED"
	title_label.modulate = Color.RED
	message_screen.visible = true
	
	# Freeze game
	get_tree().paused = true

# When we touch the Finish Zone
func show_win():
	title_label.text = "VICTORY!"
	title_label.modulate = Color.GREEN
	message_screen.visible = true
	
	get_tree().paused = true

func _on_restart_button_pressed():

	get_tree().paused = false
	# game manager restarts the game
	GameManager.start_game(GameManager.current_difficulty)
