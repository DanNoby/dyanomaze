extends Node3D

@export_group("Settings")
@export var tiles_folder: String = "res://assets/tiles/"
@export var grid_width: int = 9
@export var grid_height: int = 9

@export_group("Tuning")
@export var tile_spacing: float = 2.0  # Distance between centers (Keep 2.0 to match pillars)
@export var visual_scale: float = 0.9  # Scale multiplier

var available_tiles: Array[PackedScene] = []

func _ready():
	load_tiles_from_folder()
	
	# DEBUG: Print what we found so we know it worked
	print("Found ", available_tiles.size(), " tiles.")
	
	if available_tiles.size() > 0:
		generate_floor()

func load_tiles_from_folder():
	var dir = DirAccess.open(tiles_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Ignore folders and hidden files (starting with .)
			if !dir.current_is_dir() and !file_name.begins_with("."):
				# Check for correct file types
				if file_name.ends_with(".glb") or file_name.ends_with(".tscn"):
					
					var full_path = tiles_folder + "/" + file_name
					var tile_scene = load(full_path)
					
					if tile_scene:
						available_tiles.append(tile_scene)
			
			file_name = dir.get_next()
		
		# Close the directory stream (Good practice)
		dir.list_dir_end()
	else:
		print("ERROR: Could not open folder: " + tiles_folder)

func generate_floor():
	# Calculate start position to center the grid
	var start_x = -((grid_width * tile_spacing) / 2.0) + (tile_spacing / 2.0)
	var start_z = -((grid_height * tile_spacing) / 2.0) + (tile_spacing / 2.0)

	for x in range(grid_width):
		for z in range(grid_height):
			spawn_tile(start_x + (x * tile_spacing), start_z + (z * tile_spacing))

func spawn_tile(x_pos, z_pos):
	var random_tile_scene = available_tiles.pick_random()
	var new_tile = random_tile_scene.instantiate()
	
	new_tile.position = Vector3(x_pos, 0, z_pos)
	new_tile.scale = Vector3(visual_scale, visual_scale, visual_scale)
	
	# Random Rotation
	var random_rot = randi_range(0, 3) * 90
	new_tile.rotation_degrees.y = random_rot
	
	add_child(new_tile)
