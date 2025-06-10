@tool
extends Area3D

var tick: bool = false
var col: Shape3D

@export var properties: Dictionary

const plant_block_scene = preload("res://scenes/scenery/plants/plants.tscn")

func _process(_delta: float) -> void:
	if tick: return
	tick = true
	for i in get_children():
		if i is CollisionShape3D:
			col = i.shape
			i.disabled = true
		else:
			i.free()
	var plant_block: Plants = plant_block_scene.instantiate()
	plant_block.size = Global.util.get_size_from_points(col.points)
	plant_block.plants_per_unit_area = properties["density"]
	add_child(plant_block)
	plant_block.make()
