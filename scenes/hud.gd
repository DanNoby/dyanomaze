extends CanvasLayer

# Connect to our UI elements
@onready var message_screen = $MessageScreen
@onready var title_label = $MessageScreen/TitleLabel
@onready var health_label = $HealthLabel

func _ready():
	# 1. Hide the menu initially
	message_screen.visible = false
	
	# 2. Update hearts immediately to match the starting difficulty
	update_heart_display(GameManager.current_hearts)
	
	# 3. Listen for signals from the GameManager
	GameManager.health_changed.connect(update_heart_display)
	GameManager.game_over.connect(show_game_over)
	GameManager.level_complete.connect(show_win)

# Updates the text when we get hit
func update_heart_display(amount):
	var txt = "Hearts: "
	# Add a heart icon for every point of health we have
	for i in range(amount):
		txt += "♥ "
	health_label.text = txt

# Called when we run out of hearts
func show_game_over():
	title_label.text = "YOU DIED"
	title_label.modulate = Color.RED
	message_screen.visible = true
	
	# Freeze the game
	get_tree().paused = true

# Called when we touch the Finish Zone
func show_win():
	title_label.text = "VICTORY!"
	title_label.modulate = Color.GREEN
	message_screen.visible = true
	
	# Freeze the game
	get_tree().paused = true

# Connected to the button
func _on_restart_button_pressed():
	# Unfreeze before reloading!
	get_tree().paused = false
	# Tell the manager to restart the game
	GameManager.start_game(GameManager.current_difficulty)
