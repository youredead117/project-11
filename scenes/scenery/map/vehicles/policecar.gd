extends StaticBody3D

func _ready() -> void:
	$AnimationTree.set("parameters/TimeScale/scale", Global.rng.randf_range(0.85, 1.15))
