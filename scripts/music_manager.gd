extends Node

@onready var menu_music = $MenuMusic
@onready var game_music = $GameMusic

func play_menu_music():
	# Stop the game music, but play menu music (only if it isn't already playing)
	game_music.stop()
	if not menu_music.playing:
		menu_music.play()

func play_game_music():
	# Stop menu music, and either start or resume the game music
	menu_music.stop()
	if not game_music.playing:
		game_music.play()
	else:
		game_music.stream_paused = false # Unfreeze the track

func pause_game_music():
	# Freeze the game track where it is, and kick on the menu track
	game_music.stream_paused = true
	menu_music.play()
