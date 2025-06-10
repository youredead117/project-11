@tool
extends Area3D
class_name WaterBlock

const water_shader: ShaderMaterial = preload("res://shaders/water_shader.tres")
@export var properties: Dictionary

var tick: bool = false

func _ready() -> void:
	tick = true
	for i in get_children():
		if i is MeshInstance3D:
			i.material_override = water_shader
	
func _physics_process(_delta: float) -> void:
	if !tick && Engine.is_editor_hint():
		tick = true
		for i in get_children():
			if i is MeshInstance3D:
				i.material_override = water_shader
	if properties["killer"] != 0:
		for i in get_overlapping_bodies():
			if i is Player:
				Global.root.world.request_damage.rpc(i.name, 100.0, Vector3.INF, i.name, DeathInfo.Cause.Map)
