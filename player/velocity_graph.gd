extends MeshInstance3D

@export var player: Player
@onready var mark: MeshInstance3D = $Node3D/VelocityMark
@export var scale_graph: float

func _process(delta: float) -> void:
	var rel_vel: Vector3 = player.get_relative_velocity(player.head, player.velocity)
	var dir: Vector3 = rel_vel.normalized()
	rel_vel = dir * sqrt(rel_vel.length()) * Vector3(1.0, 2.5, 1.0)
	mark.position.x = rel_vel.y * scale_graph
	mark.position.z = rel_vel.x * scale_graph
	if mark.position.length() >= 1.5:
		mark.position = mark.position.normalized() * 1.5
