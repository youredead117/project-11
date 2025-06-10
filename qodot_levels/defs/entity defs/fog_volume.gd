@tool
extends Area3D

@export var properties: Dictionary

var fog_block: FogVolume
var fog_mat: FogMaterial
var col: Shape3D

var tick: bool = false

func _process(_delta: float) -> void:
	if tick: return
	tick = true
	for i in get_children():
		if i is CollisionShape3D:
			col = i.shape
			i.disabled = true
		if i is FogVolume:
			return
	fog_mat = FogMaterial.new()
	fog_mat.density = properties["density"]
	fog_mat.albedo = Color(	properties["color_r"] / 255.0,
							properties["color_g"] / 255.0,
							properties["color_b"] / 255.0,)
	fog_mat.emission = Color(	properties["color_r"] * properties["energy"] / 255.0,
								properties["color_g"] * properties["energy"] / 255.0,
								properties["color_b"] * properties["energy"] / 255.0,)
	fog_block = FogVolume.new()
	fog_block.material = fog_mat
	fog_block.size = Global.util.get_size_from_points(col.points)
	fog_block.layers = 1
	add_child(fog_block)
