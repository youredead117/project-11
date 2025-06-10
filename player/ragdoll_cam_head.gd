extends Node3D
class_name RagdollCam

@onready var cam: Camera3D = $rot/cam
@onready var rot: Node3D = $rot
@onready var player: Player = get_parent().get_parent()
@onready var ray: RayCast3D = $rot/ray

@export var follow_bone: PhysicalBone3D
const CAM_SENSITIVITY: float = 0.0025

var active: bool = false

func _input(event) -> void:
	if event is InputEventMouseMotion && !Global.root.console.active:
		rotate_y(-event.relative.x * CAM_SENSITIVITY)
		rot.rotate_x(event.relative.y * CAM_SENSITIVITY)
		rot.rotation.x = clamp(rot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func activate() -> void:
	if not player.is_multiplayer_authority(): return
	cam.current = true
	active = true
	
func deactivate() -> void:
	if not player.is_multiplayer_authority(): return
	active = false
	cam.current = false

func _process(delta: float) -> void:
	if !active: return
	if not player.is_multiplayer_authority(): return
	
	if ray.get_collider():
		cam.global_position = ray.get_collision_point()
		cam.force_update_transform()
		cam.position.z += 0.1
	else:
		cam.position = Vector3(0.0, 0.0, -4.5)
		
	global_position = follow_bone.global_position
