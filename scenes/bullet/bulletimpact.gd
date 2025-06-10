extends GPUParticles3D

var water: bool = false

func _ready() -> void:
	if water:
		$GPUParticlesAttractorSphere3D/GPUParticles3D.emitting = true

func _on_finished() -> void:
	queue_free()
