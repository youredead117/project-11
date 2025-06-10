extends AnimatableBody3D
class_name MovingPlatform

@export var properties: Dictionary

var movement_speed: Vector3

func _ready() -> void:
	movement_speed.x = deg_to_rad(properties["movement_speed_x"])
	movement_speed.y = deg_to_rad(properties["movement_speed_y"])
	movement_speed.z = deg_to_rad(properties["movement_speed_z"])
	movement_speed /= Engine.physics_ticks_per_second

func test_movement(test_node: Node3D, global_pos: Vector3, from_player: Player) -> Vector3:
	
	test_node.reparent(self) #parent the test node and set the pos
	test_node.global_position = global_pos
	test_node.force_update_transform()
	
	step_movement() #perform the movement
	force_update_transform()
	test_node.force_update_transform()
	
	var result_pos: Vector3 = test_node.global_position
	
	undo_movement() #undo the movement
	force_update_transform()
	test_node.reparent(from_player)
	
	return result_pos

func step_movement() -> void:
	global_position += movement_speed
	
func undo_movement() -> void:
	global_position -= movement_speed
