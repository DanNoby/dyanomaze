extends MeshInstance3D

@export var flow_speed = Vector2(0.05, 0.05)
var material: StandardMaterial3D

func _ready():
	# Grab the material we just made
	material = get_active_material(0)

func _process(delta):
	if material:
		# Slowly scroll the texture across the massive plane
		material.uv1_offset += Vector3(flow_speed.x * delta, flow_speed.y * delta, 0)
