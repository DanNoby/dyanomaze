extends StaticBody3D

# --- TUNING KNOBS ---
@export var safe_time: float = 2   # The "Window to Move" (Walls are DOWN)
@export var warning_time: float = 1.5 # Reaction time (Spikes are PEEKING)
@export var deadly_time: float = 1.0  # How long it blocks the path (Walls are UP)

var start_delay: float = 0.0
@onready var kill_zone = $Area3D
@onready var mesh = $MeshInstance3D # Just in case we need it later

enum {SAFE, WARNING, DEADLY}
var current_state = SAFE

func _ready():
	position.y = -3.0 # Start hidden
	# Waiting for MazeContainer to call initialize()...

func initialize(assigned_delay):
	start_delay = assigned_delay
	await get_tree().create_timer(start_delay).timeout
	start_trap_cycle()

func start_trap_cycle():
	while true:
		# --- PHASE 1: SAFE (The Window to Move) ---
		# This is the "walls go DOWN" moment you asked for.
		current_state = SAFE
		var tween = create_tween()
		tween.tween_property(self, "position:y", -3.0, 0.5) # Go down smooth
		
		# We wait here for the full "Safe Time"
		await get_tree().create_timer(safe_time).timeout
		
		# --- PHASE 2: WARNING (Spikes Peek) ---
		current_state = WARNING
		tween = create_tween()
		tween.tween_property(self, "position:y", -1.8, 0.2) # Spikes poke out
		
		# Give player time to react
		await get_tree().create_timer(warning_time).timeout
		
		# --- PHASE 3: DEADLY (Wall Up) ---
		current_state = DEADLY
		tween = create_tween()
		tween.tween_property(self, "position:y", 0.0, 0.1) # Snap up fast
		
		check_for_player_kill()
		
		# Wall stays up for a bit (Blocking the path)
		await get_tree().create_timer(deadly_time).timeout

func check_for_player_kill():
	var bodies = kill_zone.get_overlapping_bodies()
	for body in bodies:
		# Check if the body has the 'hit' function we just wrote
		if body.has_method("hit"):
			body.hit()

func die():
	print("Player Died!")
	get_tree().reload_current_scene()

func _on_area_3d_body_entered(body):
	if current_state == DEADLY:
		if body.has_method("hit"):
			body.hit()
