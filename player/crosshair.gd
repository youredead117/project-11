extends MeshInstance2D

func _process(_delta: float) -> void:
	position = get_viewport_rect().size / 2.0
