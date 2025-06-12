extends Node
class_name BulletSpawner

const bullet_scene = preload("res://scenes/bullet/bullet.tscn")

var num: int = 1

func make_bullet_local(spawn_pos: Vector3, dir_pos: Vector3, deviation: Vector3, shooter: StringName, speed: float, damage: float, cause: DeathInfo.Cause) -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.damage = damage
	bullet.damaging = is_multiplayer_authority()
	bullet.shooter = shooter
	Global.root.world.add_child(bullet)
	bullet.cause = cause
	bullet.hide()
	bullet.global_position = spawn_pos
	bullet.direction = ((dir_pos - spawn_pos).normalized() * speed) + deviation

func make_melee(pos: Vector3, rot: Vector3, from_player: StringName, damage: float) -> void:
	var bullet: Bullet = bullet_scene.instantiate()
	bullet.damaging = is_multiplayer_authority()
	bullet.shooter = from_player
	bullet.melee = true
	Global.root.world.add_child(bullet)
	bullet.hide()
	bullet.global_position = pos
	bullet.global_rotation = rot
	bullet.damage = damage
	bullet.direction = Vector3.ZERO
	bullet.cause = DeathInfo.Cause.Knife

func make_melee_definite(pos: Vector3, target_name: StringName, from_player: StringName, damage: float) -> void:
	Global.root.world.request_damage.rpc(StringName(target_name), damage, pos, from_player, DeathInfo.Cause.Knife)
