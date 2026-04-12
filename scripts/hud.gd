extends CanvasLayer

# --- EXISTING HUD VARIABLES ---
@onready var message_screen = $MessageScreen
@onready var title_label = $MessageScreen/TitleLabel
@onready var health_label = $HealthLabel

# --- NEW SETTINGS VARIABLES ---
@onready var pause_menu = $PauseMenu
@onready var tps_button = $PauseMenu/VBoxContainer/CameraToggles/TPSButton
@onready var fps_button = $PauseMenu/VBoxContainer/CameraToggles/FPSButton
@onready var master_slider = $PauseMenu/VBoxContainer/MasterSlider
@onready var fullscreen_toggle = $PauseMenu/VBoxContainer/FullScreenToggle
@onready var resume_button = $PauseMenu/VBoxContainer/ResumeButton
@onready var quit_button = $PauseMenu/VBoxContainer/QuitButton
@onready var sens_slider = $PauseMenu/VBoxContainer/SensSlider

func _ready():
	# Initial Visibility
	quit_button.pressed.connect(quit_game)
	message_screen.visible = false
	pause_menu.visible = false
	
	# Existing GameManager connections
	update_heart_display(GameManager.current_hearts)
	GameManager.health_changed.connect(update_heart_display)
	GameManager.game_over.connect(show_game_over)
	GameManager.level_complete.connect(show_win)
	
	if GlobalSettings.prefer_fps:
		fps_button.button_pressed = true
	else:
		tps_button.button_pressed = true
	fps_button.toggled.connect(_on_fps_toggled)
	tps_button.toggled.connect(_on_tps_toggled)
	
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = GlobalSettings.master_vol
	fullscreen_toggle.button_pressed = GlobalSettings.is_fullscreen

	master_slider.value_changed.connect(_on_master_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	resume_button.pressed.connect(resume_game)
	
	# Setup the Sensitivity Slider
	sens_slider.min_value = 0.001
	sens_slider.max_value = 0.01
	sens_slider.step = 0.0005
	sens_slider.value = GlobalSettings.mouse_sens

	# Connect the signal
	sens_slider.value_changed.connect(_on_sens_changed)

# --- PAUSE MENU LOGIC ---
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Don't let them pause if they are dead or just won!
		if message_screen.visible:
			return
			
		if pause_menu.visible:
			resume_game()
		else:
			pause_game()

func pause_game():
	pause_menu.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Unlock mouse

func resume_game():
	pause_menu.visible = false
	get_tree().paused = false
	get_viewport().gui_release_focus()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# --- SETTINGS LOGIC ---
func _on_master_changed(value: float):
	GlobalSettings.master_vol = value
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_fullscreen_toggled(toggled_on: bool):
	GlobalSettings.is_fullscreen = toggled_on
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()
	
func _on_fps_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.prefer_fps = true
		GlobalSettings.save_settings()
		var player = get_tree().get_first_node_in_group("player")
		if player: player.set_view_mode(true)

func _on_tps_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.prefer_fps = false
		GlobalSettings.save_settings()
		var player = get_tree().get_first_node_in_group("player")
		if player: player.set_view_mode(false)
	
func _on_sens_changed(value: float):
	GlobalSettings.mouse_sens = value
	GlobalSettings.save_settings()
	
func update_heart_display(amount):
	var txt = " HP "
	for i in range(amount):
		txt += "♥ "
	health_label.text = txt

func show_game_over():
	title_label.text = "YOU DIED"
	title_label.modulate = Color(1, 0, 0)
	message_screen.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func show_win():
	title_label.text = "VICTORY!"
	title_label.modulate = Color(0, 1, 0)
	message_screen.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 

func _on_restart_button_pressed():
	get_tree().paused = false
	GameManager.start_game(GameManager.current_difficulty)
	
func quit_game():
	get_tree().quit()
