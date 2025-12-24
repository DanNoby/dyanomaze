extends Node3D

func _ready():
	# The 9x9 Map layout (0=Safe start, 1=Offset, 2=delayed)
	var layout = [
		2, 2, 0, 0, 0, 0, 0, 2, 2,
		2, 1, 0, 2, 2, 2, 0, 1, 2,
		0, 0, 0, 2, 1, 2, 0, 0, 0,
		0, 2, 2, 2, 0, 2, 2, 2, 0,
		0, 1, 0, 0, 0, 0, 0, 1, 0,
		0, 2, 2, 2, 0, 2, 2, 2, 0,
		0, 0, 0, 2, 1, 2, 0, 0, 0,
		2, 1, 0, 2, 2, 2, 0, 1, 2,
		2, 2, 0, 0, 0, 0, 0, 2, 2
	]
	
	# Get all children (The TrapWalls)
	var walls = get_children()
	
	# Safety Check: Do we have enough walls?
	if walls.size() < 81:
		print("ERROR: MazeContainer needs 81 walls, but found ", walls.size())
		return

	# Loop through the walls and assign delays
	for i in range(walls.size()):
		var wall = walls[i]
		
		# Check if the wall script has the 'initialize' function
		if wall.has_method("initialize"):
			# Pass the number from the layout array (0, 1, or 2)
			wall.initialize(float(layout[i]))
