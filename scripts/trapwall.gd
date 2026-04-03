extends StaticBody3D

# Trapwall elements
@export var safe_time: float = 2   # The "Window to Move" (Walls are DOWN)
@export var warning_time: float = 1.5 # Reaction time (Spikes are PEEKING)
@export var deadly_time: float = 1.0  # How long it blocks the path (Walls are UP)

var start_delay: float = 0.0
@onready var kill_zone = $Area3D
@onready var mesh = $MeshInstance3D

var worm_scene = preload("res://scenes/worm.tscn") 
var powerup_scene = preload("res://scenes/powerup.tscn") 

enum {SAFE, WARNING, DEADLY}
var current_state = SAFE

func _ready():
	position.y = -3.0 

func initialize(assigned_delay):
	start_delay = assigned_delay
	await get_tree().create_timer(start_delay).timeout
	start_trap_cycle()

func start_trap_cycle():
	while true:
		# Safe phase
		current_state = SAFE
		var tween = create_tween()
		tween.tween_property(self, "position:y", -3.0, 0.5) # Go down smooth
		
		var roll = randf()
	
		# spawn chance for a Worm
		if roll < 0.02:
			spawn_worm()
		
		if roll > 0.85: 
			spawn_powerup()
		
		# Waiting for the full Safe period
		await get_tree().create_timer(safe_time).timeout
		
		# Spikes peeking phase
		current_state = WARNING
		tween = create_tween()
		tween.tween_property(self, "position:y", -1.8, 0.2) # Spikes poke out
		
		# Give player time to react
		await get_tree().create_timer(warning_time).timeout
		
		# Wall up deadly phase
		current_state = DEADLY
		tween = create_tween()
		tween.tween_property(self, "position:y", 0.0, 0.1) # Snap up fast
			
		check_for_player_kill()
		
		# walls blocking path
		await get_tree().create_timer(deadly_time).timeout
		
func spawn_worm():
	var worm = worm_scene.instantiate()
	get_tree().current_scene.add_child(worm)
	worm.global_position = Vector3(global_position.x, 0.5, global_position.z)

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	get_tree().current_scene.add_child(powerup)
	
	powerup.global_position = global_position + Vector3(0, 1.2, 0)

func check_for_player_kill():
	var bodies = kill_zone.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("hit"):
			body.hit()

func die():
	print("Player Died!")
	get_tree().reload_current_scene()

func _on_area_3d_body_entered(body):
	if current_state == DEADLY:
		if body.has_method("hit"):
			body.hit()
