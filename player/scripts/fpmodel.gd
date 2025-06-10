extends Camera3D
class_name FPModel

var old_velocity: Vector3
var old_diff: Vector3

@export var player: Player
@export var movement_multiplier: float
@export var max_movement: float = 0.2

func _physics_process(delta: float) -> void:
	var unclamped: Vector3 = player.velocity - old_velocity
	var clamped: Vector3 = Vector3(	clamp(unclamped.x, -max_movement, max_movement),
									clamp(unclamped.y, -max_movement, max_movement),
									clamp(unclamped.z, -max_movement, max_movement))
	var diff: Vector3 = lerp(old_diff, clamped, 0.05)
	old_diff = diff
	old_velocity = player.velocity
	$FPMover.global_position = global_position + (diff * movement_multiplier)
	$FPMover.position.y -= 0.145
