extends Node

var save_path = "user://settings.cfg"
var config = ConfigFile.new()

var master_vol: float = 1.0
var is_fullscreen: bool = false
var mouse_sens: float = 0.003
var prefer_fps: bool = false

func _ready():
	load_settings()

func save_settings():
	config.set_value("Audio", "master", master_vol)
	config.set_value("Video", "fullscreen", is_fullscreen)
	config.set_value("Controls", "mouse_sens", mouse_sens)
	config.set_value("Controls", "prefer_fps", prefer_fps)
	config.save(save_path)

func load_settings():
	if config.load(save_path) != OK: 
		return
	
	master_vol = config.get_value("Audio", "master", 1.0)
	is_fullscreen = config.get_value("Video", "fullscreen", false)
	mouse_sens = config.get_value("Controls", "mouse_sens", 0.003)
	mouse_sens  = max(mouse_sens, 0.001) 
	prefer_fps = config.get_value("Controls", "prefer_fps", false)
	apply_settings()

func apply_settings():
	var master_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_vol))

	if is_fullscreen:
		get_window().mode = Window.MODE_FULLSCREEN 
	else:
		get_window().mode = Window.MODE_WINDOWED
