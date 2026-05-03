extends Node3D

@export var enemy_scene: PackedScene
@export var mug_scene: PackedScene

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
@export var collapse_delay: float = 5.0 
@export var row_collapse_speed: float = 0.75  
@export var float_height: float = 5.0 
@export var sand_color: Color = Color(0.87, 0.653, 0.435, 1.0) 

@export_group("Infinite Generation")
@export var player: Node3D # player scene
@export var trapwall_scene: PackedScene # Trapwall scene 
@export var forward_buffer_rows: int = 5 # How many rows to keep ahead of the player
 
var front_z: float = 0.0 # Tracks the Z-coordinate of the furthest spawned row
var start_x: float = 0.0 # Stores our horizontal starting position

# The memory bank holding our grid
var current_safe_col: int = 4
var tile_rows: Array[Array] = []
var collapse_timer: Timer

var available_tiles: Array[PackedScene] = []
var obsidian_material: StandardMaterial3D # The master material

func _ready():
	setup_obsidian_material()
	load_tiles_from_folder()
	
	if available_tiles.size() > 0:
		generate_floor()

func _process(_delta):
	# Don't do anything if the player is dead or missing
	if player == null or not is_instance_valid(player): 
		return
		
	# Calculate how close the player is to the very front edge of the map
	var distance_to_front = abs(player.global_position.z - front_z)

	# If they get within 8 rows of the edge, spawn a new row!
	if distance_to_front < (forward_buffer_rows * tile_spacing):
		spawn_full_row(front_z + tile_spacing)

# forging the master material once
func setup_obsidian_material():
	obsidian_material = StandardMaterial3D.new()
	obsidian_material.albedo_color = Color(0.02, 0.02, 0.02) # Pitch black
	obsidian_material.metallic = 0.9 # dark glass
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
	# saving the left-most edge of our grid
	start_x = -((grid_width * tile_spacing) / 2.0) + (tile_spacing / 2.0)

	# Start the floor slightly behind the player 
	var current_z = -tile_spacing * 2.0 

	tile_rows.clear()

	# init rows
	for i in range(10):
		spawn_full_row(current_z)
		current_z += tile_spacing # moving one row forward

	start_collapse_sequence()

func spawn_full_row(z_pos: float):
	var current_row = []
	
	# --- 1. CARVE THE INFINITE PATH ---
	# Decide where the safe path moves for this new row
	var move_roll = randi() % 100
	if move_roll >= 60 and move_roll < 80: # 20% chance to go Left
		current_safe_col -= 1
	elif move_roll >= 80: # 20% chance to go Right
		current_safe_col += 1
		
	# Clamp it so the path doesn't accidentally run off the edge of the map!
	current_safe_col = clamp(current_safe_col, 0, grid_width - 1)

	# --- 2. BUILD THE ROW ---
	for x in range(grid_width):
		var current_x = start_x + (x * tile_spacing)
		var tile = spawn_tile(current_x, z_pos)
		current_row.append(tile)
		
		# Spawn a pillar on 60% of tiles to create a maze, 
		# OR absolutely guarantee one spawns if it is on the safe path!
		if randf() < 0.75 or x == current_safe_col:
			if trapwall_scene != null:
				var trap = trapwall_scene.instantiate()
				trap.position = Vector3(current_x, 0.0, z_pos) 
				add_child(trap) 
				
				if trap.has_method("initialize"):
					var delay = 0.0
					
					# 3. APPLY THE MAZE PROBABILITIES
					if x == current_safe_col:
						delay = 0.0 # FORCED SAFE PATH
					else:
						var rand_val = randi() % 10
						if rand_val < 3:
							delay = 0.0 # 30% Safe
						elif rand_val < 6:
							delay = 1.0 # 30% Warning
						else:
							delay = 2.0 # 40% Danger
							
					trap.initialize(delay)

		# NOTE: We completely deleted the Enemy and Mug spawns from here 
		# because the Trapwalls are taking that job back!
			
	tile_rows.append(current_row)
	front_z = z_pos

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
	# If the array is empty (player outran the map somehow), do nothing
	if tile_rows.size() == 0: 
		return
	var row_to_destroy = tile_rows.pop_front()
	
	if row_to_destroy.size() == 0: 
		return
		
	var current_row_z = row_to_destroy[0].global_position.z

	# Animate the floor tiles
	for tile in row_to_destroy:
		if is_instance_valid(tile):
			animate_death(tile)

	# Sweep for Trapwalls and Enemies
	for entity in get_tree().get_nodes_in_group("destructibles"):
		if is_instance_valid(entity):
			if abs(entity.global_position.z - current_row_z) <= (tile_spacing / 2.0):
				animate_death(entity)

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
