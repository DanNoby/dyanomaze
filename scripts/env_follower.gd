extends Node3D

@export var player: Node3D
@export var z_offset: float = 0.0 

func _process(_delta):
	if is_instance_valid(player):
		global_position.z = player.global_position.z + z_offset
