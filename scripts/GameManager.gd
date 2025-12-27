extends Node

# Signal to tell the UI to update when we take damage
signal health_changed(new_amount)
signal game_over
signal level_complete

# Difficulty Settings
enum Difficulty { EASY, MEDIUM, HARD }
var current_difficulty = Difficulty.EASY

var max_hearts: int = 3
var current_hearts: int = 3

func start_game(difficulty_mode):
	current_difficulty = difficulty_mode
	
	# Set hearts based on mode
	match current_difficulty:
		Difficulty.EASY:
			max_hearts = 3
		Difficulty.MEDIUM:
			max_hearts = 2
		Difficulty.HARD:
			max_hearts = 1
	
	current_hearts = max_hearts
	# Reset the game scene
	get_tree().reload_current_scene()

func take_damage():
	current_hearts -= 1
	emit_signal("health_changed", current_hearts)
	
	if current_hearts <= 0:
		emit_signal("game_over")
