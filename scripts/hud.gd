extends CanvasLayer

# Standard HUD variables
@onready var health_label = $HealthLabel
@onready var canvas_group = $PauseMenu/CanvasGroup
@onready var crt_spark = $CRTSpark

# Settings variables
@onready var pause_menu = $PauseMenu
@onready var main_menu_screen = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen
@onready var logo_label = $PauseMenu/CanvasGroup/VBoxContainer/LogoLabel
@onready var final_score_label = $PauseMenu/CanvasGroup/VBoxContainer/FinalScoreLabel
@onready var options_screen = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen

# MAIN MENU
@onready var resume_btn = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/ResumeButton
@onready var options_btn = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/OptionsButton
@onready var quit_btn = $PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/QuitButton
@onready var back_btn = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/BackButton

# --- VIDEO TAB ---
@onready var fullscreen_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/FullScreenToggle
@onready var fov_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/FOVSlider
@onready var shake_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/ShakeToggle
@onready var hud_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Video/MarginContainer/GridContainer/HUDToggle

# --- AUDIO TAB ---
@onready var output_dropdown = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/OutputDropdown
@onready var master_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/MasterSlider
@onready var music_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/MusicSlider
@onready var sfx_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Audio/MarginContainer/GridContainer/SFXSlider

# --- GAMEPLAY TAB ---
@onready var tps_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/TPSButton
@onready var fps_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/FPSButton
@onready var keyboard_btn = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/KeyboardButton
@onready var controller_btn = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/ControllerButton
@onready var invert_toggle = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/InvertToggle
@onready var sens_slider = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Gameplay/MarginContainer/GridContainer/SensSlider

# --- CONTROLS TAB ---
@onready var remap_overlay = $PauseMenu/RemapOverlay
@onready var up_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Controls/MarginContainer/GridContainer/UpButton
@onready var down_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Controls/MarginContainer/GridContainer/DownButton
@onready var left_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Controls/MarginContainer/GridContainer/LeftButton
@onready var right_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Controls/MarginContainer/GridContainer/RightButton
@onready var attack_button = $PauseMenu/CanvasGroup/VBoxContainer/OptionsScreen/TabContainer/Controls/MarginContainer/GridContainer/AttackButton

@onready var score_ui = $ScoreLabel
@onready var health_ui = $HealthLabel

var is_remapping: bool = false
var is_transitioning: bool = false
var action_to_remap: String = ""
var button_to_update: Button = null
var current_game_state: String = "PLAYING"

func _ready():
	# Initial Visibility
	quit_btn.pressed.connect(quit_game)
	options_btn.pressed.connect(_on_options_button_pressed)
	back_btn.pressed.connect(_on_back_button_pressed)
	hud_toggle.button_pressed = GlobalSettings.show_hud
	if score_ui: score_ui.visible = GlobalSettings.show_hud
	if health_ui: health_ui.visible = GlobalSettings.show_hud
	pause_menu.visible = false
	remap_overlay.visible = false
	
	main_menu_screen.show()
	options_screen.hide()
	
	# Existing GameManager connections
	update_heart_display(GameManager.current_hearts)
	update_button_text(up_button, "ui_up")
	update_button_text(down_button, "ui_down")
	update_button_text(left_button, "ui_left")
	update_button_text(right_button, "ui_right")
	update_button_text(attack_button, "ui_accept")
	
	GameManager.health_changed.connect(update_heart_display)
	GameManager.game_over.connect(show_game_over)
	GameManager.level_complete.connect(show_win)
	hud_toggle.toggled.connect(_on_hud_toggled)
	
	if GlobalSettings.prefer_fps:
		fps_button.button_pressed = true
	else:
		tps_button.button_pressed = true
	
	if GlobalSettings.use_controller:
		controller_btn.button_pressed = true
	else:
		keyboard_btn.button_pressed = true
	
	master_slider.max_value = 1.0
	master_slider.step = 0.05
	master_slider.value = GlobalSettings.master_vol
	fullscreen_toggle.button_pressed = GlobalSettings.is_fullscreen
	invert_toggle.button_pressed = GlobalSettings.invert_y

	# Sensitivity Slider
	sens_slider.min_value = 0.001
	sens_slider.max_value = 0.01
	sens_slider.step = 0.0005
	sens_slider.value = GlobalSettings.mouse_sens
	
	fov_slider.min_value = 70
	fov_slider.max_value = 120
	fov_slider.step = 1
	fov_slider.value = GlobalSettings.fov
	shake_toggle.button_pressed = GlobalSettings.screen_shake

	# Connect the signal
	fps_button.toggled.connect(_on_fps_toggled)
	tps_button.toggled.connect(_on_tps_toggled)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	invert_toggle.toggled.connect(_on_invert_toggled)
	resume_btn.pressed.connect(resume_game)
	sens_slider.value_changed.connect(_on_sens_changed)
	fov_slider.value_changed.connect(_on_fov_changed)
	shake_toggle.toggled.connect(_on_shake_toggled)
	keyboard_btn.toggled.connect(_on_keyboard_toggled)
	controller_btn.toggled.connect(_on_controller_toggled)
	output_dropdown.item_selected.connect(_on_output_selected)
	
	up_button.pressed.connect(_on_remap_button_pressed.bind("ui_up", up_button))
	down_button.pressed.connect(_on_remap_button_pressed.bind("ui_down", down_button))
	left_button.pressed.connect(_on_remap_button_pressed.bind("ui_left", left_button))
	right_button.pressed.connect(_on_remap_button_pressed.bind("ui_right", right_button))
	attack_button.pressed.connect(_on_remap_button_pressed.bind("ui_accept", attack_button))
	connect_all_buttons(pause_menu)
	
	music_slider.max_value = 1.0; music_slider.step = 0.05
	sfx_slider.max_value = 1.0; sfx_slider.step = 0.05
	music_slider.value = GlobalSettings.music_vol
	sfx_slider.value = GlobalSettings.sfx_vol

# Pause menu logic
func _input(event):
	if is_remapping:
		if event is InputEventKey and event.pressed:
			var keycode = event.physical_keycode
			var actions_to_check = ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept"]
			for action in actions_to_check:
				if action != action_to_remap: 
					for existing_event in InputMap.action_get_events(action):
						if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
							
							button_to_update.text = "Taken!"
							await get_tree().create_timer(0.8).timeout

							update_button_text(button_to_update, action_to_remap) 

							is_remapping = false
							remap_overlay.visible = false
							get_viewport().set_input_as_handled()
							return
			
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keycode
			for e in InputMap.action_get_events(action_to_remap):
				if e is InputEventKey:
					InputMap.action_erase_event(action_to_remap, e)
			InputMap.action_add_event(action_to_remap, new_event)

			GlobalSettings.keybinds[action_to_remap] = keycode
			GlobalSettings.save_settings()
			
			button_to_update.text = OS.get_keycode_string(keycode)

			is_remapping = false
			remap_overlay.visible = false  
			
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("toggle_pause"):
		if is_transitioning or current_game_state != "PLAYING":
			return
			
		if pause_menu.visible:
			resume_game()
		else:
			pause_game()

func _process(_delta):
	if pause_menu.visible:
		canvas_group.queue_redraw()
		logo_label.queue_redraw()

func pause_game():
	if current_game_state == "PLAYING":
		logo_label.text = "[center][shake rate=20.0 level=6 connected=1]DYANOMAZE[/shake][/center]"
		final_score_label.hide()
		resume_btn.text = "RESUME"
	
	is_transitioning = true
	get_tree().paused = true # immediately stop game
	$SwitchAudio.play()

	# Tv boot
	crt_spark.scale = Vector2.ZERO
	crt_spark.modulate.a = 1.0
	crt_spark.show()

	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(crt_spark, "scale", Vector2(1.5, 1.5), 0.04)
	tween.tween_property(crt_spark, "scale", Vector2(15.0, 0.05), 0.05) 
	tween.tween_property(crt_spark, "modulate:a", 0.0, 0.03) 

	await tween.finished
	crt_spark.hide()

	# show UI
	pause_menu.visible = true
	main_menu_screen.show()
	options_screen.hide()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$PauseMenu/CanvasGroup/VBoxContainer/MainMenuScreen/ResumeButton.grab_focus()
	update_audio_dropdown()

	is_transitioning = false

func resume_game():
	if is_transitioning: return 
	
	is_transitioning = true
	$SwitchAudio.play()

	# Hide UI
	pause_menu.visible = false
	get_viewport().gui_release_focus()
	
	# Tv gone animation
	crt_spark.scale = Vector2(15.0, 0.05)
	crt_spark.modulate.a = 1.0
	crt_spark.show()

	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(crt_spark, "scale", Vector2(0.5, 0.5), 0.05) 
	tween.tween_property(crt_spark, "scale", Vector2.ZERO, 0.05)

	await tween.finished
	crt_spark.hide()

	# unpause game
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_transitioning = false
	
	if current_game_state == "DEAD" or current_game_state == "WON":
		current_game_state = "PLAYING" 
		GameManager.start_game(GameManager.current_difficulty)

# Settings logic
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
	
func _on_fov_changed(value: float):
	GlobalSettings.fov = value
	GlobalSettings.save_settings()

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("update_fov"): 
		player.update_fov(value)

func update_button_text(button: Button, action: String):
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			button.text = OS.get_keycode_string(event.physical_keycode)

func _on_remap_button_pressed(action: String, button: Button):
	action_to_remap = action
	button_to_update = button
	is_remapping = true
	remap_overlay.visible = true

func _on_shake_toggled(toggled_on: bool):
	GlobalSettings.screen_shake = toggled_on
	GlobalSettings.save_settings()
	
func _on_music_changed(value: float):
	GlobalSettings.music_vol = value
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_sfx_changed(value: float):
	GlobalSettings.sfx_vol = value
	GlobalSettings.apply_settings()
	GlobalSettings.save_settings()

func _on_invert_toggled(toggled_on: bool):
	GlobalSettings.invert_y = toggled_on
	GlobalSettings.save_settings()
	
func _on_keyboard_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.use_controller = false
		GlobalSettings.save_settings()

func _on_controller_toggled(toggled_on: bool):
	if toggled_on:
		GlobalSettings.use_controller = true
		GlobalSettings.save_settings()
		
func _on_hud_toggled(toggled_on: bool):
	GlobalSettings.show_hud = toggled_on
	GlobalSettings.save_settings()

	if score_ui: score_ui.visible = toggled_on
	if health_ui: health_ui.visible = toggled_on

func _on_output_selected(index: int):
	# Get the exact name of the device they just clicked
	var selected_device = output_dropdown.get_item_text(index)
	
	GlobalSettings.audio_device = selected_device
	GlobalSettings.save_settings()
	GlobalSettings.apply_settings()
	
func update_audio_dropdown():
	output_dropdown.clear()
	var devices = AudioServer.get_output_device_list()
	
	if devices.is_empty():
		devices.append("Default")

	for i in range(devices.size()):
		output_dropdown.add_item(devices[i])
		
		# Re-select the player's saved preference
		if devices[i] == GlobalSettings.audio_device:
			output_dropdown.select(i)
			
func _on_options_button_pressed():
	main_menu_screen.hide()
	options_screen.show()

func _on_back_button_pressed():
	options_screen.hide()
	main_menu_screen.show()
	
func update_heart_display(amount):
	var txt = " HP "
	for i in range(amount):
		txt += "♥ "
	health_label.text = txt

func show_game_over():
	current_game_state = "DEAD"

	logo_label.text = "[center][color=red][shake rate=20.0 level=6 connected=1]YOU DIED[/shake][/color][/center]"

	final_score_label.text = "FINAL " + score_ui.text
	final_score_label.show()
	
	resume_btn.text = "RESTART"

	pause_game() 

func show_win():
	current_game_state = "WON"

	logo_label.text = "[center][color=green][shake rate=20.0 level=6 connected=1]VICTORY![/shake][/color][/center]"
	
	final_score_label.text = "FINAL " + score_ui.text
	final_score_label.show()
	
	resume_btn.text = "RESTART"
	
	pause_game()
	
func play_button_sound(): 
	$SwitchAudio.play()

func connect_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton: 
			if not child.pressed.is_connected(play_button_sound):
				child.pressed.connect(play_button_sound)
		
		connect_all_buttons(child)
	
func quit_game():
	get_tree().quit()
