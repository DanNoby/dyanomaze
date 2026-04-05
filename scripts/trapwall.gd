extends StaticBody3D

@export var safe_time: float = 2.0   
@export var warning_time: float = 1.5 
@export var deadly_time: float = 1.0  
@export var glow_gradient: Gradient

var start_delay: float = 0.0
@onready var kill_zone = $Area3D
@onready var mesh = $MeshInstance3D/pillar

var worm_scene = preload("res://scenes/worm.tscn") 
var powerup_scene = preload("res://scenes/powerup.tscn") 

enum {SAFE, WARNING, DEADLY}
var current_state = SAFE
var material: StandardMaterial3D 

func _ready():
	position.y = -3.0 
	
	material = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	material.emission_enabled = true
	material.emission_energy_multiplier = 0.0

func set_glow_color(weight: float):
	if glow_gradient:
		material.emission = glow_gradient.sample(weight)

func initialize(assigned_delay):
	start_delay = assigned_delay
	await get_tree().create_timer(start_delay).timeout
	start_trap_cycle()

func start_trap_cycle():
	while true:
		current_state = SAFE
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position:y", -3.0, 0.5) 
		tween.tween_property(material, "emission_energy_multiplier", 1, 0.2)
		tween.tween_method(set_glow_color, 1.0, 0.0, 0.5)
		
		var roll = randf()
		if roll < 0.02:
			spawn_worm()
		if roll > 0.95: 
			spawn_powerup()
		
		await get_tree().create_timer(safe_time).timeout
		
		# --- WARNING PHASE ---
		current_state = WARNING
		tween = create_tween()
		tween.set_parallel(true) 
		tween.tween_property(self, "position:y", -1.8, 0.2) 
		tween.tween_property(material, "emission_energy_multiplier", 4.0, warning_time)

		tween.tween_method(set_glow_color, 0.0, 1.0, 0.2)
		$AudioWarning.play()

		await get_tree().create_timer(warning_time).timeout
		
		# --- DEADLY PHASE ---
		current_state = DEADLY
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position:y", 0.0, 0.1) 

		# THE FIX: Fade from RED (1.0) back to GREEN (0.0) over the duration it stays up
		tween.tween_method(set_glow_color, 1.0, 0.0, deadly_time)
		$AudioStrike.play()
			
		check_for_player_kill()

		await get_tree().create_timer(deadly_time).timeout
		
func spawn_worm():
	var worm = worm_scene.instantiate()
	get_tree().current_scene.add_child(worm)
	worm.global_position = Vector3(global_position.x, 0.5, global_position.z)

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	get_tree().current_scene.add_child(powerup)
	powerup.global_position = Vector3(global_position.x, 2, global_position.z)

func check_for_player_kill():
	var bodies = kill_zone.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("hit"):
			body.hit()

func _on_area_3d_body_entered(body):
	if current_state == DEADLY:
		if body.has_method("hit"):
			body.hit()
