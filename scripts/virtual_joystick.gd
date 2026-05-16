extends Control

@onready var knob = $Knob
var center_pos = Vector2.ZERO
var max_radius = 75.0 # How far the knob can be dragged
var is_dragging = false
var touch_index = -1

func _ready():
	# Calculate the exact center of this Control box
	center_pos = size / 2.0
	knob.position = center_pos - (knob.size / 2.0)

func _gui_input(event):
	# Detect when the thumb touches the joystick area
	if event is InputEventScreenTouch:
		if event.pressed and not is_dragging:
			is_dragging = true
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			is_dragging = false
			touch_index = -1
			# Snap back to center
			knob.position = center_pos - (knob.size / 2.0)
			release_all_directions()

	# Detect when the thumb slides around
	if event is InputEventScreenDrag and is_dragging and event.index == touch_index:
		var thumb_pos = event.position
		var direction = thumb_pos - center_pos
		
		# Prevent the knob from leaving the circle
		if direction.length() > max_radius:
			direction = direction.normalized() * max_radius
			
		knob.position = (center_pos + direction) - (knob.size / 2.0)
		
		# Translate the thumb position into keyboard presses
		send_input(direction / max_radius)

func send_input(dir: Vector2):
	# Horizontal (A / D)
	if dir.x > 0.1:
		Input.action_press("ui_right", dir.x)
		Input.action_release("ui_left")
	elif dir.x < -0.1:
		Input.action_press("ui_left", abs(dir.x))
		Input.action_release("ui_right")
	else:
		Input.action_release("ui_right")
		Input.action_release("ui_left")

	# Vertical (W / S)
	if dir.y > 0.1:
		Input.action_press("ui_down", dir.y)
		Input.action_release("ui_up")
	elif dir.y < -0.1:
		Input.action_press("ui_up", abs(dir.y))
		Input.action_release("ui_down")
	else:
		Input.action_release("ui_down")
		Input.action_release("ui_up")

func release_all_directions():
	Input.action_release("ui_up")
	Input.action_release("ui_down")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
