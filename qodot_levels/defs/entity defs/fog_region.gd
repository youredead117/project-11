extends Area3D
class_name FogRegion

@export var properties: Dictionary

var light_color: Color
var density: float
var energy: float

func _ready() -> void:
	
	light_color = Color(float(properties["color_r"]) / 255.0,
						float(properties["color_g"]) / 255.0,
						float(properties["color_b"]) / 255.0,)
	
	density = clamp(properties["density"], 0.0, 1.0)
	energy = properties["energy"]
