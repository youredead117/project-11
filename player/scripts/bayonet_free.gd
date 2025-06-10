@tool
extends Node3D

@export var set_pos: bool = false
@export var fixed_bayonet: Node3D

func _process(delta: float) -> void:
	if set_pos:
		set_pos = false
		global_transform = fixed_bayonet.global_transform
