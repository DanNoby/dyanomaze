extends Node3D

@export_group("Settings")
@export var tiles_folder: String = "res://assets/tiles/"
@export var grid_width: int = 9
@export var grid_height: int = 9

@export_group("Tuning")
@export var tile_spacing: float = 2.0 
@export var visual_scale: float = 0.9  

@export_group("Obsidian Material")
@export var glow_color: Color = Color(0.01, 0.01, 0.01) # Default dark purple glow
@export var glow_intensity: float = 2.0

var available_tiles: Array[PackedScene] = []
var obsidian_material: StandardMaterial3D # The master material

func _ready():
	setup_obsidian_material()
	load_tiles_from_folder()
	
	if available_tiles.size() > 0:
		generate_floor()

# 1. Forge the master material once
func setup_obsidian_material():
	obsidian_material = StandardMaterial3D.new()
	obsidian_material.albedo_color = Color(0.02, 0.02, 0.02) # Pitch black
	obsidian_material.metallic = 0.9 # Obsidian is basically dark glass
	obsidian_material.roughness = 0.1 # Very shiny and smooth
	
	# Enable the glow
	obsidian_material.emission_enabled = true
	obsidian_material.emission = glow_color
	obsidian_material.emission_energy_multiplier = glow_intensity

func load_tiles_from_folder():
	var dir = DirAccess.open(tiles_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and !file_name.begins_with("."):
				if file_name.ends_with(".glb") or file_name.ends_with(".tscn"):
					var full_path = tiles_folder + "/" + file_name
					var tile_scene = load(full_path)
					
					if tile_scene:
						available_tiles.append(tile_scene)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

func generate_floor():
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
	
	var random_rot = randi_range(0, 3) * 90
	new_tile.rotation_degrees.y = random_rot
	
	# 2. Paint the tile before adding it to the scene
	apply_obsidian_to_meshes(new_tile)
	
	add_child(new_tile)

# 3. Recursively dig through the tile to find any meshes and override their materials
func apply_obsidian_to_meshes(node: Node):
	if node is MeshInstance3D and node.mesh != null:
		# Loop through all surfaces in case the mesh has multiple parts
		for i in range(node.mesh.get_surface_count()):
			node.set_surface_override_material(i, obsidian_material)
			
	# Check all children (handles .glb files where the mesh is nested inside other nodes)
	for child in node.get_children():
		apply_obsidian_to_meshes(child)
