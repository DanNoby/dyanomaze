extends Node3D

func _ready():
	randomize()
	
	var walls = get_children()
	
	# STEP 1: PURE CHAOS
	# Assign a random delay to every single wall first
	for wall in walls:
		# Randomly pick 0.0, 1.0, or 2.0
		# We use weighted random to make "Safe" spots slightly rarer
		var rand_val = randi() % 10 # 0 to 9
		if rand_val < 3:
			wall.initialize(0.0) # 30% chance of Safe
		elif rand_val < 6:
			wall.initialize(1.0) # 30% chance of Warning
		else:
			wall.initialize(2.0) # 40% chance of Danger
			
	# STEP 2: CARVE THE GOLDEN PATH
	# We force a path from bottom-center to top-center to be Safe (0.0)
	carve_path(walls)

func carve_path(walls):
	# Grid settings
	var width = 9
	
	# Start at bottom center (x=4, y=8)
	var current_x = 4
	var current_y = 8
	
	# Loop until we reach the top row (y=0)
	while current_y >= 0:
		# 1. Force the current tile to be SAFE (0.0)
		var index = current_y * width + current_x
		if index < walls.size():
			walls[index].initialize(0.0)
		
		# 2. Decide next move: Go UP, LEFT, or RIGHT?
		# We bias it to go UP so it actually finishes.
		var move_roll = randi() % 100
		
		if move_roll < 60: # 60% chance to go UP
			current_y -= 1
		elif move_roll < 80: # 20% chance Left
			if current_x > 0: # Check bounds
				current_x -= 1
		else: # 20% chance Right
			if current_x < width - 1: # Check bounds
				current_x += 1
		
		# Safety check: Prevent infinite loops if it gets stuck moving left/right
		# If we stayed in the same Y row too long, force Up next time.
