extends RayCast3D
class_name Bullet

@export var direction: Vector3 = Vector3.ONE
var shooter: StringName
var countdown: int = 2
const bullet_impact = preload("res://scenes/bullet/bulletimpact.tscn")
const bullet_impact_water = preload("res://scenes/bullet/bulletimpact_water.tscn")
@onready var light: OmniLight3D = $OmniLight3D
var damage: float = 20.0
var damaging: bool = false

var melee: bool = false

var cause: DeathInfo.Cause

func _ready() -> void:
	hide()
	if melee:
		target_position = Vector3(0.0, 0.0, -1.5)
		hit_from_inside = false
		hit_back_faces = false
		countdown = (-10 * Engine.physics_ticks_per_second) + 4
	
func _physics_process(delta: float) -> void:
	damage -= delta * 4.0
	damage = clamp(damage, 1.0, INF)
	countdown -= 1
	if countdown == 0 && !melee:
		show()
	if countdown <= -1 * Engine.physics_ticks_per_second && light != null:
		light.queue_free()
	if countdown <= -10 * Engine.physics_ticks_per_second:
		queue_free()
	if !melee:
		look_at(global_position + direction)
		global_position += direction * delta
	if get_collider() != null:
		if get_collider().name != shooter:
			if get_collider() is WaterBlock:
				var impact: GPUParticles3D = bullet_impact_water.instantiate()
				impact.water = true
				Global.root.world.add_child(impact)
				impact.global_position = get_collision_point()
				impact.emitting = true
			elif get_collider() is Player:
				if damaging:
					Global.root.world.request_damage.rpc(StringName(get_collider().name), damage, get_collision_point(), shooter, cause)
			else:
				var impact: GPUParticles3D = bullet_impact.instantiate()
				Global.root.world.add_child(impact)
				impact.global_position = get_collision_point()
				impact.emitting = true
			queue_free()
			
