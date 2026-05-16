extends CanvasLayer 

@onready var main_menu_screen = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen
@onready var options_screen = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen
@onready var high_score_label = $PauseMenu/CanvasGroup/VBoxContainer/HighScoreLabel
@onready var play_btn = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/ResumeButton
@onready var options_btn = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/OptionsButton
@onready var quit_btn = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/QuitButton
@onready var back_btn = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/BackButton
@onready var output_dropdown = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/OutputDropdown

@onready var fullscreen_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/FullScreenToggle
@onready var fov_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/FOVSlider
@onready var master_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/MasterSlider
@onready var music_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/MusicSlider
@onready var sfx_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/SFXSlider
@onready var sens_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/SensSlider

@onready var tps_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/TPSButton
@onready var fps_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/FPSButton
@onready var keyboard_btn = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/KeyboardButton
@onready var controller_btn = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/ControllerButton
@onready var invert_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/InvertToggle
@onready var shake_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/ShakeToggle
@onready var hud_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/HUDToggle

func _ready():
	MusicManager.play_menu_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	high_score_label.show() 
	high_score_label.text = "BEST SCORE: " + str(GlobalSettings.best_score)
	
	master_slider.max_value = 1.0; master_slider.step = 0.05
	music_slider.max_value = 1.0; music_slider.step = 0.05
	sfx_slider.max_value = 1.0; sfx_slider.step = 0.05
	
	fov_slider.min_value = 70; fov_slider.max_value = 120; fov_slider.step = 1
	sens_slider.min_value = 0.001; sens_slider.max_value = 0.01; sens_slider.step = 0.0005
	
	update_audio_dropdown()
	output_dropdown.item_selected.connect(_on_output_selected)
	
	fullscreen_toggle.button_pressed = GlobalSettings.is_fullscreen
	fov_slider.value = GlobalSettings.fov
	master_slider.value = GlobalSettings.master_vol
	music_slider.value = GlobalSettings.music_vol
	sfx_slider.value = GlobalSettings.sfx_vol
	sens_slider.value = GlobalSettings.mouse_sens
	
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	fov_slider.value_changed.connect(_on_fov_changed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sens_slider.value_changed.connect(_on_sens_changed)
	
	fps_button.button_pressed = GlobalSettings.prefer_fps
	tps_button.button_pressed = not GlobalSettings.prefer_fps
	controller_btn.button_pressed = GlobalSettings.use_controller
	keyboard_btn.button_pressed = not GlobalSettings.use_controller
	invert_toggle.button_pressed = GlobalSettings.invert_y
	shake_toggle.button_pressed = GlobalSettings.screen_shake
	hud_toggle.button_pressed = GlobalSettings.show_hud

	fps_button.toggled.connect(_on_fps_toggled)
	tps_button.toggled.connect(_on_tps_toggled)
	keyboard_btn.toggled.connect(_on_keyboard_toggled)
	controller_btn.toggled.connect(_on_controller_toggled)
	invert_toggle.toggled.connect(_on_invert_toggled)
	shake_toggle.toggled.connect(_on_shake_toggled)
	hud_toggle.toggled.connect(_on_hud_toggled)
	
	if play_btn: play_btn.grab_focus()

func _on_play_button_pressed():
	$SwitchAudio.play()
	await get_tree().create_timer(0.15).timeout 
	get_tree().change_scene_to_file("res://scenes/main.tscn") 

func _on_options_button_pressed():
	$SwitchAudio.play()
	main_menu_screen.hide()
	options_screen.show()

func _on_back_button_pressed():
	$SwitchAudio.play()
	options_screen.hide()
	main_menu_screen.show()

func _on_quit_button_pressed():
	$SwitchAudio.play()
	# Wait for the click before Godot kills the application
	await get_tree().create_timer(0.15).timeout 
	get_tree().quit()

func _on_master_changed(value: float):
	GlobalSettings.master_vol = value
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_music_changed(value: float):
	GlobalSettings.music_vol = value
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_sfx_changed(value: float):
	GlobalSettings.sfx_vol = value
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_fullscreen_toggled(toggled_on: bool):
	GlobalSettings.is_fullscreen = toggled_on
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_fov_changed(value: float):
	GlobalSettings.fov = value
	GlobalSettings.save_settings()

func _on_sens_changed(value: float):
	GlobalSettings.mouse_sens = value
	GlobalSettings.save_settings()
	
func update_audio_dropdown():
	output_dropdown.clear()
	var devices = AudioServer.get_output_device_list()
	
	if devices.is_empty():
		devices.append("Default")

	for i in range(devices.size()):
		output_dropdown.add_item(devices[i])
		if devices[i] == GlobalSettings.audio_device:
			output_dropdown.select(i)

func _on_output_selected(index: int):
	var selected_device = output_dropdown.get_item_text(index)
	GlobalSettings.audio_device = selected_device
	GlobalSettings.save_settings()
	GlobalSettings.apply_settings()

func _on_fps_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.prefer_fps = true
		GlobalSettings.save_settings()

func _on_tps_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.prefer_fps = false
		GlobalSettings.save_settings()

func _on_keyboard_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.use_controller = false
		GlobalSettings.save_settings()

func _on_controller_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.use_controller = true
		GlobalSettings.save_settings()

func _on_invert_toggled(toggled_on: bool):
	GlobalSettings.invert_y = toggled_on
	GlobalSettings.save_settings()

func _on_shake_toggled(toggled_on: bool):
	GlobalSettings.screen_shake = toggled_on
	GlobalSettings.save_settings()

func _on_hud_toggled(toggled_on: bool):
	GlobalSettings.show_hud = toggled_on
	GlobalSettings.save_settings()
