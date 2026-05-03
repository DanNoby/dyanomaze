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

@export_group("Collapse Mechanic")
@export var collapse_delay: float = 5.0 # How long before the floor starts falling
@export var row_collapse_speed: float = 1.0 # Seconds between each row breaking
@export var float_height: float = 5.0 # How high they float before disappearing
@export var sand_color: Color = Color(0.87, 0.653, 0.435, 1.0) # Default sandy brown

# The memory bank holding our grid
var tile_rows: Array[Array] = []
var current_row_to_break: int = 0
var collapse_timer: Timer

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
				var clean_name = file_name.trim_suffix(".remap").trim_suffix(".import")
				
				if clean_name.ends_with(".glb") or clean_name.ends_with(".tscn"):
					# Use the cleaned name to build the path
					var full_path = tiles_folder + "/" + clean_name
					var tile_scene = load(full_path)

					if tile_scene:
						available_tiles.append(tile_scene)    
			file_name = dir.get_next()
		
		dir.list_dir_end()

func generate_floor():
	var start_x = -((grid_width * tile_spacing) / 2.0) + (tile_spacing / 2.0)
	var start_z = -((grid_height * tile_spacing) / 2.0) + (tile_spacing / 2.0)

	tile_rows.clear()

	# SWAPPED: Loop Z first, so we gather horizontal rows!
	for z in range(grid_height):
		var current_row = []
		for x in range(grid_width):
			var tile = spawn_tile(start_x + (x * tile_spacing), start_z + (z * tile_spacing))
			current_row.append(tile)

		# finished row to the master list
		tile_rows.append(current_row)
	start_collapse_sequence()

func spawn_tile(x_pos, z_pos) -> Node3D:
	var random_tile_scene = available_tiles.pick_random()
	var new_tile = random_tile_scene.instantiate()
	
	new_tile.position = Vector3(x_pos, 0, z_pos)
	new_tile.scale = Vector3(visual_scale, visual_scale, visual_scale)
	
	var random_rot = randi_range(0, 3) * 90
	new_tile.rotation_degrees.y = random_rot
	
	apply_obsidian_to_meshes(new_tile)
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	
	var actual_size = tile_spacing / visual_scale
	box.size = Vector3(actual_size, 0.5, actual_size)
	
	collision_shape.shape = box
	
	collision_shape.position.y = 0.75
	
	static_body.add_child(collision_shape)
	new_tile.add_child(static_body)
	add_child(new_tile)
	
	return new_tile

# Recursively dig through the tile to find any meshes and override their materials
func apply_obsidian_to_meshes(node: Node):
	if node is MeshInstance3D and node.mesh != null:
		# Loop through all surfaces in case the mesh has multiple parts
		for i in range(node.mesh.get_surface_count()):
			node.set_surface_override_material(i, obsidian_material)
			
	# Check all children (handles .glb files where the mesh is nested inside other nodes)
	for child in node.get_children():
		apply_obsidian_to_meshes(child)

func start_collapse_sequence():

	await get_tree().create_timer(collapse_delay, false).timeout

	# Create an invisible ticking clock to break rows continuously
	collapse_timer = Timer.new()
	collapse_timer.wait_time = row_collapse_speed
	collapse_timer.timeout.connect(collapse_next_row)
	add_child(collapse_timer)
	collapse_timer.start()

func collapse_next_row():
	if current_row_to_break >= tile_rows.size():
		collapse_timer.stop()
		return

	var row_to_destroy = tile_rows[current_row_to_break]

	# Safety check, and grabbing the exact Z-coordinate line of this row
	if row_to_destroy.size() == 0: return 
	var current_row_z = row_to_destroy[0].global_position.z

	# 1. Animate the floor tiles
	for tile in row_to_destroy:
		if is_instance_valid(tile):
			animate_death(tile)

	# 2. SWEEP FOR TRAPWALLS AND ENEMIES!
	# Find everything in the "destructibles" group...
	for entity in get_tree().get_nodes_in_group("destructibles"):
		if is_instance_valid(entity):
			if abs(entity.global_position.z - current_row_z) <= (tile_spacing / 2.0):
				animate_death(entity)
				
	current_row_to_break += 1

func animate_death(target_node: Node3D):
	disable_all_collisions(target_node)
	
	var tween = create_tween().set_parallel(true)
	var anim_duration = randf_range(1.5, 2.5) 
	
	var random_x = randf_range(-3.0, 3.0) 
	var random_z = randf_range(-1.0, 4.0) 
	var target_pos = target_node.global_position + Vector3(random_x, float_height, random_z)
	var random_rot = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
	morph_color_to_sand(target_node, tween, anim_duration)
	
	tween.tween_property(target_node, "global_position", target_pos, anim_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target_node, "rotation", random_rot, anim_duration)
	tween.tween_property(target_node, "scale", Vector3(0.001, 0.001, 0.001), anim_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	
	tween.chain().tween_callback(target_node.queue_free)
	
func disable_all_collisions(node: Node):
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
		node.set_process(false)
		node.set_physics_process(false)

	if node is CollisionShape3D or node is CollisionPolygon3D:
		node.set_deferred("disabled", true)
		
	if node is CSGShape3D:
		node.use_collision = false

	for child in node.get_children():
		disable_all_collisions(child)

func morph_color_to_sand(node: Node, tween: Tween, duration: float):
	if node is MeshInstance3D and node.mesh != null:
		for i in range(node.mesh.get_surface_count()):
			# Grab the current material on the mesh
			var current_mat = node.get_active_material(i)
			
			if current_mat and current_mat is StandardMaterial3D:
				# TRAP AVOIDED: Duplicate the material so it becomes unique to THIS specific dying piece!
				var unique_mat = current_mat.duplicate()
				node.set_surface_override_material(i, unique_mat)
				
				# Tween the base color to your sandy brown
				tween.tween_property(unique_mat, "albedo_color", sand_color, duration)
				
				# If the material was glowing (like your obsidian), fade the glow to pure black so it looks "dead"
				if unique_mat.emission_enabled:
					tween.tween_property(unique_mat, "emission", Color.BLACK, duration)

	# Recursively dig through children (important for Trapwalls which might have multiple mesh parts)
	for child in node.get_children():
		morph_color_to_sand(child, tween, duration)
