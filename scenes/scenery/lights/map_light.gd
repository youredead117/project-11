extends Node3D
class_name MapLight

@export var properties: Dictionary

var tick: bool = false

func _ready() -> void:
	$container/subcontainer/OmniLight3D.light_energy = properties["energy"]
	$container/subcontainer/OmniLight3D.omni_range = properties["range"] * 2.0
	#$container/OmniLight3D.BakeMode = Light3D.BakeMode.BAKE_DYNAMIC
	$container/subcontainer.rotation.x = 0.0
	$container.rotation_degrees.y = 90.0 * properties["rotate"]

func _process(_delta: float) -> void:
	if !tick:
		if $ray.get_collider():
			var norm: Vector3 = $ray.get_collision_normal()
			global_position = $ray.get_collision_point()
			look_at(global_position + norm)
		tick = true
