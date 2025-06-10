@tool
extends StaticBody3D
class_name SeeThru

var tick: bool = false

func _ready() -> void:
	tick = true
	for i in get_children():
		if i is MeshInstance3D:
			i.material_override.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	
func _physics_process(_delta: float) -> void:
	if !tick && Engine.is_editor_hint():
		tick = true
		for i in get_children():
			if i is MeshInstance3D:
				i.material_override.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
