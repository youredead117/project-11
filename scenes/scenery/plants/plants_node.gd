@tool
extends Node3D
class_name Plants

var size: Vector3

@export var plants_per_unit_area: float = 2.5

@onready var ray: RayCast3D = $ray
var plant_nodes: Array[PlantSettings] = []

const plant_scenes = [	preload("res://models/low_poly_plants/scenes/fern_multi.tscn"),
						preload("res://models/low_poly_plants/scenes/fern_single.tscn"),
						preload("res://models/low_poly_plants/scenes/floor_branch.tscn"),
						preload("res://models/low_poly_plants/scenes/leafy_shit.tscn")]

func make() -> void:
	var area: float = size.x * size.z
	var num_plants: int = int(plants_per_unit_area * area)
	for i in range(0, num_plants):
		var p: PlantSettings = plant_scenes[Global.util.repeat_rng.randi_range(0, plant_scenes.size() - 1)].instantiate()
		plant_nodes.append(p)
		add_child(p)
		p.position.x = Global.util.repeat_rng.randf_range(-size.x / 2.0, size.x / 2.0)
		p.position.z = Global.util.repeat_rng.randf_range(-size.z / 2.0, size.z / 2.0)
		p.global_position.y = get_ray_collision(p.position)
		p.global_rotation_degrees.x = Global.util.repeat_rng.randf_range(-p.max_rotation_degrees_x, p.max_rotation_degrees_x)
		p.global_rotation_degrees.z = Global.util.repeat_rng.randf_range(-p.max_rotation_degrees_z, p.max_rotation_degrees_z)
		p.global_rotation.y = Global.util.repeat_rng.randf()
		p.scale.x = Global.util.repeat_rng.randf_range(0.8, 1.1)
		p.scale.y = Global.util.repeat_rng.randf_range(0.8, 1.1)
		p.scale.z = Global.util.repeat_rng.randf_range(0.8, 1.1)

func get_ray_collision(pos: Vector3) -> float:
	var h: float = 0.0
	ray.position = pos
	ray.position.y = 0.0
	ray.force_raycast_update()
	ray.force_raycast_update()
	if ray.get_collider():
		h = ray.get_collision_point().y
	return h
