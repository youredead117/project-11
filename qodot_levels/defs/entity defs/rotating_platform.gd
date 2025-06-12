extends AnimatableBody3D
class_name RotatingPlatform

@export var properties: Dictionary

var rotation_speed: Vector3

var rotation_speed_move: Vector3

func _ready() -> void:
	rotation_speed.x = deg_to_rad(properties["rotation_speed_degrees_x"])
	rotation_speed.y = deg_to_rad(properties["rotation_speed_degrees_y"])
	rotation_speed.z = deg_to_rad(properties["rotation_speed_degrees_z"])
	rotation_speed_move = rotation_speed
	rotation_speed /= Engine.physics_ticks_per_second

func test_movement(test_node: Node3D, global_pos: Vector3, from_player: Player) -> Vector3:
	var current_transform = global_transform
	
	# Calculate player's position relative to platform's origin (local space)
	var local_offset = current_transform.affine_inverse() * global_pos
	
	# Rotate platform basis temporarily
	var rotated_basis = current_transform.basis.rotated(Vector3.RIGHT, rotation_speed.x)
	rotated_basis = rotated_basis.rotated(Vector3.UP, rotation_speed.y)
	rotated_basis = rotated_basis.rotated(Vector3.FORWARD, rotation_speed.z)

	# Construct a simulated rotated transform
	var rotated_transform = Transform3D(rotated_basis, current_transform.origin)

	# Apply it to the original local offset
	var new_global_pos = rotated_transform * local_offset

	return new_global_pos

func step_movement() -> void:
	rotation.y = rotation_speed_move.y * Global.root.world.round_time_elapsed

func _physics_process(delta: float) -> void:
	step_movement()
