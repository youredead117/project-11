extends Node3D
class_name PlayerSpawner

var tries: int = 0

func _ready() -> void:
	hide()
	Global.root.world.player_spawners.append(self)
	
func get_spawn_pos(first_try: bool = true) -> Vector3:
	$RayCast3D.force_update_transform()
	$RayCast3D.force_raycast_update()
	if first_try:
		tries = 0
	var pos: Vector3
	if $RayCast3D.get_collider():
		return $RayCast3D.get_collision_point()
	elif tries < 50:
		tries += 1
		position.y += 0.1
		force_update_transform()
		return get_spawn_pos(false)
	else:
		return Vector3.INF
