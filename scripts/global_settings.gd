extends Node

var save_path = "user://settings.cfg"
var config = ConfigFile.new()
var use_controller: bool = false
var show_hud: bool = true
var audio_device: String = "Default"

var master_vol: float = 1.0
var is_fullscreen: bool = false
var mouse_sens: float = 0.003
var prefer_fps: bool = false
var fov: float = 90.0
var screen_shake: bool = true 
var music_vol: float = 1.0
var sfx_vol: float = 1.0
var invert_y: bool = false
var keybinds: Dictionary = {}
var default_keybinds: Dictionary = {
	"ui_up": KEY_W,
	"ui_down": KEY_S,
	"ui_left": KEY_A,
	"ui_right": KEY_D,
	"ui_accept": KEY_SPACE
}

func _ready():
	load_settings()

func save_settings():
	config.set_value("Audio", "master", master_vol)
	config.set_value("Audio", "music", music_vol) 
	config.set_value("Audio", "sfx", sfx_vol)
	config.set_value("Audio", "audio_device", audio_device)
	
	config.set_value("Video", "show_hud", show_hud) 
	config.set_value("Video", "fullscreen", is_fullscreen)
	config.set_value("Video", "fov", fov) 
	config.set_value("Video", "screen_shake", screen_shake)
	
	config.set_value("Controls", "mouse_sens", mouse_sens)
	config.set_value("Controls", "prefer_fps", prefer_fps)
	config.set_value("Controls", "invert_y", invert_y)
	config.set_value("Controls", "keybinds", keybinds)
	config.set_value("Controls", "use_controller", use_controller)
	config.save(save_path)

func load_settings():
	if config.load(save_path) != OK: 
		keybinds = default_keybinds.duplicate()
		apply_settings()
		apply_keybinds()
		return
	
	master_vol = config.get_value("Audio", "master", 1.0)
	music_vol = config.get_value("Audio", "music", 1.0)
	sfx_vol = config.get_value("Audio", "sfx", 1.0)
	audio_device = config.get_value("Audio", "audio_device", "Default")
	show_hud = config.get_value("Video", "show_hud", true)
	is_fullscreen = config.get_value("Video", "fullscreen", false)
	fov = config.get_value("Video", "fov", 90.0) 
	screen_shake = config.get_value("Video", "screen_shake", true)
	mouse_sens = config.get_value("Controls", "mouse_sens", 0.003)
	mouse_sens  = max(mouse_sens, 0.001) 
	prefer_fps = config.get_value("Controls", "prefer_fps", false)
	invert_y = config.get_value("Controls", "invert_y", false)
	keybinds = config.get_value("Controls", "keybinds", default_keybinds.duplicate())
	use_controller = config.get_value("Controls", "use_controller", false)

	apply_settings()
	apply_keybinds()

func apply_settings():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_vol))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_vol))
	AudioServer.output_device = audio_device

	if is_fullscreen:
		get_window().mode = Window.MODE_FULLSCREEN 
	else:
		get_window().mode = Window.MODE_WINDOWED	

func apply_keybinds():
	for action in keybinds.keys():
		var new_event = InputEventKey.new()
		new_event.physical_keycode = keybinds[action]
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
				
		InputMap.action_add_event(action, new_event)
