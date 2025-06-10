@tool
extends BoneAttachment3D

@export var bayonet_free: Node3D
@export var bayonet_fixed: Node3D

@export var free_visible: bool = false
@export var stop_override: bool = false

func _process(delta: float) -> void:
	#override_pose = !override_pose
	if free_visible:
		bayonet_free.show()
		bayonet_fixed.hide()
	else:
		bayonet_free.hide()
		bayonet_fixed.show()
