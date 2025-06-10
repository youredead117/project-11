extends Node
class_name ServerProcessor

@onready var world = Global.root.world

func _enter_tree() -> void:
	set_multiplayer_authority(1)

@rpc("authority", "reliable")
func request_damage(victim_name: StringName, damage: float, pos: Vector3) -> void:
	print("YO")
	var pl: Player
	for i in world.players:
		if i.name == victim_name:
			pl = i
			break
	if is_instance_valid(pl):
		pl.hurt(damage, pos)
