extends CharacterBody3D
class_name Player

#enums:
enum Team{
	RED,
	BLUE,
	GREEN,
	YELLOW,
	BLACK,
	WHITE,
	PURPLE,
	BROWN,
	NONE
}

enum Permissions{
	NONE,
	Member,
	Mod,
	Admin,
	Host
}

const TEAM_COLOR = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.BLACK, Color.WHITE, Color.PURPLE, Color.BROWN]

const time_attack_bayonet: float = 1.0 #seconds taken for bayonet attack animation
const time_stab_bayonet: float = 0.0 #seconds taken since start of bayonet animation to the stab point where damage gets dealt

#controlling head movement
const CAM_SENSITIVITY: float = 0.0025
@onready var head = $Head
@onready var camera = $Head/Cam

#movement
@onready var mover = $Head/mover
@onready var mover_noclip = $Head/Cam/MoverNoclip
@export var jump_power: float = 5.0
var jump_buffer: float = 0.0
var momentum: Vector3 = Vector3.ZERO
@export var speed: float = 8.0
@export var max_speed: float = 5.0
var time_since_air: float = 0.2
@export var height_ray: RayCast3D
var slide_timer: float = 0.0
var crouch_buffer: float = 0.0
@export_flags_3d_physics var lunging_collision_layer: int

@export var moving_platform_ray: RayCast3D
@export var platform_mover_node: Node3D

#input
@export var input: InputBuffer = InputBuffer.new()

#player
var dead: bool = false
@export var health: float = 100.0

#visual
@export var anim_tree: AnimationTree
@export var bayonet_group: Array[Node3D] #group of visual nodes for bayonet including arms etc
@export var m4_group: Array[Node3D] #group of visual nodes for m4
@export var m4_recoil_model: Node3D
@onready var m4_recoil_model_quaternion_rest: Quaternion = m4_recoil_model.quaternion
const bullet_impact_blood = preload("res://scenes/bullet/bulletimpact_blood.tscn")
@export var username_display: Label3D
@export var ragdoll_cam: RagdollCam
var screenshotting: bool = false

#visual UI
@export var velocity_reading: Label3D
@export var height_reading: Label3D
@export var healthbar_mesh: MeshInstance3D
@export var height_bar: MeshInstance3D
@export var fps: Label3D
@export var HUDVP: Node
var death_popup: DeathPopup
@export var crosshair: MeshInstance2D

const death_popup_scene = preload("res://player/death_popup.tscn")

#weapons
@export var melee_ray: RayCast3D
@export var shoot_ray: RayCast3D
@export var lunge_ray: RayCast3D
@export var lunge_speed_multiplier: float
@export var bullet_spawn: Node3D
@export var default_bullet_direction: Node3D
@export var bullet_speed: float
var countdown_melee: float = 0.0
var done_melee: bool = false
var bayonet_equipped: bool = true
var timer_m4: float = 0.0
var lunge_target: Player = null
var lunge_timer: float = 0.0
var lunge_speed: float = 0.0

#dev
var noclip: bool = false
var god: bool = false
@onready var original_collision_layer: int = collision_layer
@onready var original_collision_mask: int = collision_mask

#multiplayer-replication
@export var vel: Vector3
@export var team: Team
var team_changed_timer: int = 10
@export var username: String
@export var permissions: Permissions = Permissions.Member
var death_info: DeathInfo = DeathInfo.new()
var username_iteration_number: int = 0
var muted_local: bool = false
var muted_global: bool = false
@export var steam_player_id: int

var damagers: Dictionary = {}

var tick_setup: int = 1

func get_unique_username() -> void:
	for i: Player in Global.root.world.players:
		if i.name != name && i.username == username:
			if username_iteration_number > 0:
				username = username.trim_suffix("#" + str(username_iteration_number))
			username_iteration_number += 1
			username += "#" + str(username_iteration_number)

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion && !Global.root.console.active:
		head.rotate_y(-event.relative.x * CAM_SENSITIVITY)
		camera.rotate_x(-event.relative.y * CAM_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func setup_post_ready() -> void:
	if !Global.root.world.is_multiplayer_authority():
		await multiplayer.connected_to_server
	await get_tree().create_timer(0.5).timeout
	Global.root.world.send_players_list.rpc()
	await get_tree().create_timer(0.3).timeout
	get_unique_username()
	print(username + " is unique username for node " + name)

func get_scoreboard() -> void:
	if !Global.root.world.is_multiplayer_authority():
		await multiplayer.connected_to_server
	await get_tree().create_timer(1.2).timeout
	Global.root.world.request_scoreboard.rpc()
	Global.root.world.send_world_rules.rpc()

func _ready() -> void:
	if is_multiplayer_authority():
		Global.root.world.player = self
	
	Global.root.world.player_joined(name)
	Global.root.world.players.append(self)
		
	$vis.hide()
	crosshair.hide()
	$Visual.show()
	$Head/Cam/posterizer.hide()
	$"Head/Cam/posterizer LAYER 2".hide()
	$HUDVP/HUD2.hide()
	
	for i in bayonet_group:
		i.hide()
	for i in m4_group:
		i.hide()
	
	if not is_multiplayer_authority(): return
	steam_player_id = Global.steam_id
	get_scoreboard()
	
	username = Global.steam_username
	#PERMS
	if Global.root.world.is_multiplayer_authority():
		permissions = Permissions.Host
	
	#IP ADDRESS, GONNA DELETE THIS THOUGH
	for i in IP.get_local_addresses():
		if i.begins_with("192.168"):
			Global.root.host_ip = i
			break
			
	#VISUALS
	$HUDVP/HUD2.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	crosshair.show()
	$Head/Cam/posterizer.show()
	$"Head/Cam/posterizer LAYER 2".show()
	for i in bayonet_group:
		i.show()
	camera.current = true
	$Visual.material_override.albedo_color = TEAM_COLOR[int(team)]
	
func _physics_process(delta: float) -> void:
	$Collider.disabled = dead
	
	if !is_multiplayer_authority(): return
	if tick_setup == 0:
		setup_post_ready()
		tick_setup -= 1
	else:
		tick_setup -= 1
	
	input_process()
	weapons(delta)
	
	general_movement(delta)
	
	replicate_values(delta)
	visual_processes(delta)
	
func general_movement(delta: float) -> void:
	if !dead || god:
		slide_timer -= delta
		if noclip:
			movement_noclip(delta)
		elif slide_timer > 0.0:
			movement_slide(delta)
		else:
			if bayonet_equipped:
				if lunge_timer > 0.0:
					lunge(delta)
				movement_bayonet(delta)
			else:
				lunge_timer = 0.0
				movement_m4(delta)
				
	calc_momentum(delta)
	
func replicate_values(_delta: float) -> void:
	vel = velocity
	
func _process(delta: float) -> void:
	visual_processes_non_authority()
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("screenshot"):
		screenshot()
	process_fps(delta)
	fog_region_process()


func weapons(delta: float) -> void:
	lunge_timer -= delta
	if !noclip:
		if lunge_timer > 0.0:
			collision_layer = lunging_collision_layer
			collision_mask = lunging_collision_layer
		else:
			collision_layer = original_collision_layer
			collision_mask = original_collision_mask
	timer_m4 -= delta
	
	if input.switch:
		bayonet_equipped = !bayonet_equipped
		if bayonet_equipped:
			for i in bayonet_group:
				i.show()
			for i in m4_group:
				i.hide()
		else:
			anim_tree.set("parameters/attack_bayonet/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
			countdown_melee = 0.0
			for i in bayonet_group:
				i.hide()
			for i in m4_group:
				i.show()
				
	if countdown_melee > 0.0:
		countdown_melee -= delta
		
	if input.attack_light && !dead:
		if bayonet_equipped && countdown_melee <= 0.0:
			done_melee = false
			countdown_melee = 1.0
			if !is_on_floor() && lunge_ray.get_collider() is Player:
				if lunge_ray.get_collider() != self:
					start_lunge(lunge_ray.get_collider())
			elif lunge_timer <= 0.0:
				melee_attack(melee_ray.get_collider())
				
	if input.attack_light_const && !dead:
		if !bayonet_equipped:
			m4_shot(delta)
			
	if input.reload:
		if dead:
			Global.root.world.random_spawn_player(self)
			Global.root.world.heal.rpc(name)

func melee_attack(target: CollisionObject3D) -> void:
	if lunge_timer > 0.0:
		lunge_timer = 0.5
	lunge_target = null
	anim_tree.set("parameters/attack_bayonet/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	done_melee = true
	var target_name: StringName = "NONE"
	if target is Player:
		target_name = target.name
	make_bullet_melee.rpc(camera.global_position, camera.global_rotation, target_name, name, 105.0)
		
func m4_shot(_delta: float) -> void:
	if timer_m4 <= 0.0:
		timer_m4 = 0.086 #around 700 RPM firerate
		var dir_pos: Vector3
		var deviation: Vector3
		var deviation_multiplier: float = 0.4
		if is_multiplayer_authority():
			deviation_multiplier *= m4_recoil_model.position.length()
			if !is_on_floor():
				deviation_multiplier *= 1.5
			deviation_multiplier *= 1.0 + velocity.length()
			deviation = Vector3(Global.rng.randf_range(-1.0, 1.0), Global.rng.randf_range(-1.0, 1.0), Global.rng.randf_range(-1.0, 1.0))
			deviation *= deviation_multiplier
			if shoot_ray.get_collider():
				dir_pos = shoot_ray.get_collision_point()
			else:
				dir_pos = default_bullet_direction.global_position
			
			m4_recoil_model.rotation_degrees.y -= 1.0
			m4_recoil_model.position.x -= 1.0
			m4_recoil_model.position.z += 0.1
			m4_recoil_model.rotation_degrees.x += Global.rng.randf_range(-0.5, 0.5)
			m4_recoil_model.rotation_degrees.z += Global.rng.randf_range(-0.5, 0.5)
			make_bullet.rpc(bullet_spawn.global_position, dir_pos, deviation, name, bullet_speed, 20.0, DeathInfo.Cause.M4)
	
func lerp_head_height(h: float):
	head.position.y = lerp(head.position.y, h, 0.1)
	
func start_lunge(target: Player) -> void:
	lunge_timer = 1.0
	lunge_speed = velocity.length() * lunge_speed_multiplier
	lunge_target = target
	velocity = (lunge_target.head.global_position - head.global_position) * lunge_speed * speed
	
func lunge(delta: float) -> void:
	mover.position = Vector3(0.0, 0.0, -1.0)
	var resultant: Vector3 = (mover.global_position - head.global_position) * lunge_speed
	
	velocity.x = lerp(velocity.x, resultant.x, 0.25)
	velocity.y = lerp(velocity.y, resultant.y, 0.25)
	velocity.z = lerp(velocity.z, resultant.z, 0.25)
	

	velocity = velocity.normalized() * 15.0
	
	move_and_slide()
	melee_ray.force_raycast_update()
	if melee_ray.get_collider() is Player:
		melee_attack(melee_ray.get_collider())
	
func get_platform_movement_vector(must_be_on_floor: bool = true) -> Vector3:
	var result: Vector3 = Vector3.ZERO
	
	if (!is_on_floor() && must_be_on_floor): return Vector3.ZERO
	var ray_col: CollisionObject3D = moving_platform_ray.get_collider()
	if !ray_col is RotatingPlatform && !ray_col is MovingPlatform: return Vector3.ZERO
	
	result = ray_col.test_movement(platform_mover_node, moving_platform_ray.get_collision_point(), self) - global_position
	
	if ray_col is RotatingPlatform:
		rotate_y(ray_col.rotation_speed.y)
	
	return result

func jump(vel: float) -> void:
	
	momentum = Vector3.ZERO
	
	var original_pos: Vector3 = mover.position
	var original_pos_global: Vector3 = mover.global_position
	momentum += get_platform_movement_vector(false) * 10.0 / speed
	mover.global_position += momentum
	mover.position.y = 0.0
	mover.force_update_transform()
	momentum = mover.position - original_pos
	velocity += (mover.global_position - original_pos_global) * speed
	
	velocity.y = vel
	jump_buffer = 0.0
	
func calc_momentum(_delta: float) -> void:
	if is_on_floor():
		momentum = Vector3.ZERO
	momentum = lerp(momentum, Vector3.ZERO, 0.05)
	
func movement_slide(delta: float) -> void:
	lerp_head_height(0.75)
	var resultant: Vector3 = (mover.global_position - head.global_position) * speed * (1.0 + slide_timer * slide_timer)
	
	velocity.x = lerp(velocity.x, resultant.x, 0.1)
	velocity.z = lerp(velocity.z, resultant.z, 0.1)
	if !is_on_floor():
		velocity.y -= Global.root.world.rules.gravity * delta
	
	if height_ray.get_collider():
		if (height_ray.get_collision_point() - global_position).length() >= 2.0:
			jump(jump_power)
			slide_timer = 0.0
	
	move_and_slide()
	jump_buffer = 0.1
	
func movement_bayonet(delta: float) -> void:
	lerp_head_height(1.5)
	jump_buffer -= delta
	if input.jump:
		jump_buffer = 0.15
		
	var input_vector: Vector2 = input.get_wasd().normalized()
	mover.position.x = input_vector.x
	
	if !is_on_floor():
		velocity.y -= Global.root.world.rules.gravity * delta
		if abs(input_vector.y) >= 0.1 && time_since_air <= 0.0:
			mover.position.z = input_vector.y * 0.5
		else:
			mover.position.z *= 1 + (0.12 * delta)
		mover.position *= 1 + (0.08 * delta)
		time_since_air -= delta
	else:
		time_since_air = 0.2
		if jump_buffer > 0.0 && slide_timer <= 0.0:
			jump(jump_power)
		else:
			mover.position.z = input_vector.y
	mover.position.x = clamp(mover.position.x, -max_speed, max_speed)
	mover.position.z = clamp(mover.position.z, -max_speed, max_speed)
	mover.position.x += momentum.x
	mover.position.z += momentum.z
	var resultant: Vector3 = (mover.global_position - head.global_position) * speed
	
	velocity.x = lerp(velocity.x, resultant.x, 0.1)
	velocity.z = lerp(velocity.z, resultant.z, 0.1)
	
	get_platform_movement_vector()
	
	move_and_slide()
	
	if input.crouch:
		crouch_buffer = 0.3
	if crouch_buffer > 0.0 && slide_timer <= -1.0 && is_on_floor():
		slide_timer = 1.0
		mover.global_position = head.global_position + (velocity / speed)
	crouch_buffer -= delta
	
func movement_m4(delta: float) -> void:
	slide_timer = 0.0
	lerp_head_height(1.5)
	jump_buffer -= delta
	if input.jump:
		jump_buffer = 0.15
		
	var input_vector: Vector2 = input.get_wasd().normalized()
	
	if !is_on_floor():
		velocity.y -= Global.root.world.rules.gravity * delta
		time_since_air -= delta
	else:
		time_since_air = 0.2
		if jump_buffer > 0.0 && slide_timer <= 0.0:
			jump(jump_power / 1.3)
		else:
			mover.position.x = input_vector.x
			mover.position.z = input_vector.y
	
	mover.position.x += momentum.x
	mover.position.z += momentum.z
	var resultant: Vector3 = (mover.global_position - head.global_position) * speed
	
	velocity.x = lerp(velocity.x, resultant.x, 0.1)
	velocity.z = lerp(velocity.z, resultant.z, 0.1)
	
	get_platform_movement_vector()
	
	velocity += momentum
	
	move_and_slide()
	
func movement_noclip(delta: float) -> void:
	slide_timer = 0.0
	lerp_head_height(1.5)
	var input_vector: Vector2 = input.get_wasd().normalized()
	var pos: Vector3 = Vector3(input_vector.x, 0.0, input_vector.y)
	mover_noclip.position = lerp(mover_noclip.position, pos * 25.0, 0.1)
	velocity = (mover_noclip.global_position - head.global_position)
	move_and_slide()

func input_process() -> void:
	if Global.root.console.active:
		input.set_wasd(0.0, 0.0, 0.0, 0.0)
		return
	input.set_wasd(	Input.get_action_strength("forward"),
					Input.get_action_strength("left"),
					Input.get_action_strength("back"),
					Input.get_action_strength("right"))
	input.jump = Input.is_action_just_pressed("jump")
	input.attack_heavy = Input.is_action_just_pressed("heavy_attack")
	input.attack_light = Input.is_action_just_pressed("light_attack")
	input.attack_light_const = Input.is_action_pressed("light_attack")
	input.reload = Input.is_action_just_pressed("reload")
	input.switch = Input.is_action_just_pressed("switch")
	input.crouch = Input.is_action_just_pressed("crouch")

func get_relative_velocity(cam, _vel):
	# Extract camera basis vectors
	var forward = cam.global_transform.basis.z.normalized()
	var right = cam.global_transform.basis.x.normalized() / 7.5
	var up = cam.global_transform.basis.y.normalized() / 7.5
	
	# Project velocity onto each basis vector
	var forward_component = _vel.dot(forward)
	var right_component = _vel.dot(right)
	var up_component = _vel.dot(up)
	
	return Vector3(forward_component, right_component, up_component)

func visual_processes(delta: float) -> void:
	m4_recoil_model.quaternion = lerp(m4_recoil_model.quaternion, m4_recoil_model_quaternion_rest, 0.02)
	m4_recoil_model.position = lerp(m4_recoil_model.position, Vector3.ZERO, 0.02)
	$"Head/Cam/FP Viewport/FP/FPModel - VIS LAYER 2".global_transform = camera.global_transform
	var rel_vel: Vector3
	if !dead:
		rel_vel = get_relative_velocity(camera, velocity) / 3.0
	else:
		rel_vel = get_relative_velocity(camera, Vector3(1.0, 1.0, 1.0))
		#velocity_on_death *= 1.01
	var post: ShaderMaterial = $Head/Cam/posterizer.material_override
	post.set_shader_parameter("straight_speed", lerp(post.get_shader_parameter("straight_speed"), abs(rel_vel.x), 0.05))
	post.set_shader_parameter("side_speed", lerp(post.get_shader_parameter("side_speed"), -(rel_vel.y), 0.05))
	post.set_shader_parameter("vertical_speed", lerp(post.get_shader_parameter("vertical_speed"), rel_vel.z, 0.05))
	post.set_shader_parameter("dead", dead)
	
	if dead:
		$Head/Cam/posterizer.global_position = $vis/RagdollCam/rot/cam.global_position
		$"Head/Cam/posterizer LAYER 2".hide()
	else:
		$Head/Cam/posterizer.position = Vector3.ZERO
		if !screenshotting:
			$"Head/Cam/posterizer LAYER 2".show()
	
	var vel_len: float = velocity.length()
	camera.fov = lerp(camera.fov, 70.0 + clamp(vel_len * 4.0, 20.0, 50.0), 0.06)
	#$"Head/Cam/FP Viewport/FP/FPModel - VIS LAYER 2".size = 1.0 - clamp(vel_len * 0.01, 0.0, 0.2)
	#$HUDVP/VP/cam.size = $"Head/Cam/FP Viewport/FP/FPModel - VIS LAYER 2".size
	UI_processes(delta)

func visual_processes_non_authority() -> void:
	if team_changed_timer > 0:
		$Visual.material_override.albedo_color = TEAM_COLOR[int(team)]
		team_changed_timer -= 1
	if !is_multiplayer_authority():
		if team == Global.root.world.player.team:
			username_display.no_depth_test = true
		else:
			username_display.no_depth_test = false
			if (global_position - Global.root.world.player.global_position).length() <= 30.0:
				username_display.transparency = lerp(username_display.transparency, 0.0, 0.02)
			else:
				username_display.transparency = lerp(username_display.transparency, 1.0, 0.02)
		username_display.text = username

func UI_processes(delta: float) -> void:
	#velocity reading
	velocity_reading.text = "V="
	var str_vel: String = str(velocity.length())
	str_vel += "0000"
	for i in range(0, 5):
		velocity_reading.text += str_vel[i]
	velocity_reading.text += "m/s"
	#height reading
	height_reading.text = "z="
	var str_h: String = str((global_position - height_ray.get_collision_point()).length())
	str_h += "0000"
	for i in range(0, 5):
		height_reading.text += str_h[i]
	height_reading.text += "m"
	#health
	var cursed_ahh_health_value: float = 88.15 + (11.85 * health / 100.0)
	var healthbar_mat: ShaderMaterial = healthbar_mesh.material_override
	healthbar_mat.set_shader_parameter("health", cursed_ahh_health_value)
	#height
	if !is_on_floor():
		var height: float = (global_position - height_ray.get_collision_point()).length()
		height_bar.scale.z = clamp(height / 8.0, 0.0, 1.0)
	else:
		height_bar.scale.z = 0.0
	if dead:
		pass

func process_fps(delta: float):
	#fps
	fps.text = "FPS:"
	var str_fps: String = str(1.0 / delta)
	str_fps += "0000"
	for i in range(0, 5):
		fps.text += str_fps[i]

func set_noclip(value: bool) -> void:
	noclip = value
	if noclip:
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = original_collision_layer
		collision_mask = original_collision_mask

func hurt(amt: float, pos = Vector3.INF, from: StringName = "NONE", cause: DeathInfo.Cause = DeathInfo.Cause.Map):
	if god:
		return
	if !Global.root.world.rules.friendly_fire && cause != DeathInfo.Cause.Map && cause != DeathInfo.Cause.Command:
		if Global.root.world.find_player(from).team == team:
			return
	
	
	var real_damage: float = amt
		
	if (health - amt) <= 0.0:
		real_damage = health
		ragdoll()
		
	health -= amt
	health = clamp(health, 0.0, 100.0)
	
	if health <= 0.0:
		
		dead = true
		death_info.cause = cause
		death_info.killer_node_name = from #just the node name (the multiplayer authority)
		death_info.killer_node = Global.root.world.find_player(from) #the actual Player node
		if death_info.killer_node:
			death_info.killer_username = death_info.killer_node.username #the player's username
		start_death_popup()
	
	if pos != Vector3.INF:
		var impact: GPUParticles3D = bullet_impact_blood.instantiate()
		impact.water = false
		Global.root.world.add_child(impact)
		impact.global_position = pos
		impact.emitting = true
		
	if !damagers.has(from):
		damagers[from] = 0.0
	
	damagers[from] += real_damage
	
	if dead:
		var assister_name: StringName
		var max_val_found: float
		for key in damagers:
			if damagers[key] > max_val_found:
				max_val_found = damagers[key]
				assister_name = key
				
		if assister_name == from:
			assister_name = "NONE"
		if cause == DeathInfo.Cause.Map || cause == DeathInfo.Cause.Command:
			from = "NONE"
		
		damagers.clear()
		
		Global.root.world.player_died(name, from, assister_name)
		
	Global.root.world.update_scoreboard(ScoreBoard.INDEX.DAMAGE, name, real_damage)
		
func start_death_popup() -> void:
	if !is_multiplayer_authority(): return
	if is_instance_valid(death_popup): return
	
	crosshair.hide()
	death_popup = death_popup_scene.instantiate()
	death_popup.setup_text(death_info.construct_death_text())
	HUDVP.add_child(death_popup)
		
func end_death_popup() -> void:
	if !is_multiplayer_authority(): return
	
	crosshair.show()
	if is_instance_valid(death_popup):
		death_popup.queue_free()
		
func heal() -> void:
	end_death_popup()
	dead = false
	health = 100.0
	$vis/PhysicalBoneSimulator3D.physical_bones_stop_simulation()
	$vis.hide()
	$vis.animate_physical_bones = true
	ragdoll_cam.deactivate()
	if !is_multiplayer_authority():
		$Visual.show()

func ragdoll() -> void:
	$vis.global_rotation.y = head.global_rotation.y + PI
	$Visual.hide()
	$vis.show()
	$vis/PhysicalBoneSimulator3D.physical_bones_start_simulation()
	ragdoll_cam.activate()
	for i in $vis/PhysicalBoneSimulator3D.get_children():
		if i is PhysicalBone3D:
			i.linear_velocity = vel
			const rand_impulse = 1.5
			var vec_rand: Vector3 = Vector3(	Global.util.true_rng.randf_range(-rand_impulse, rand_impulse),
												Global.util.true_rng.randf_range(-rand_impulse, rand_impulse),
												Global.util.true_rng.randf_range(-rand_impulse, rand_impulse))
												
			i.apply_central_impulse(vec_rand)
			i.gravity_scale = Global.root.world.rules.gravity / 9.81
		
func set_godmode(val: bool) -> void:
	god = val
	if god:
		dead = false


func fog_region_process() -> void:
	var color: Vector3
	var dense: float
	var energy: float
	var amt: int = 0
	for area in $Head/Cam/FogRegionSensor.get_overlapping_areas():
		if area is FogRegion:
			amt += 1
			color.x += area.light_color.r
			color.y += area.light_color.g
			color.z += area.light_color.b
			dense += area.density
			energy += area.energy
	if amt > 0:
		color.x /= float(amt)
		color.y /= float(amt)
		color.z /= float(amt)
		dense /= float(amt)
		energy /= float(amt)
		Global.root.world.environment_setter.fog_light_color = Color(color.x, color.y, color.z)
		Global.root.world.environment_setter.fog_density = dense
		Global.root.world.environment_setter.fog_light_energy = energy

@rpc("call_local")
func make_bullet(spawn_pos: Vector3, dir_pos: Vector3, deviation: Vector3, shooter: StringName, _speed: float, damage: float, cause: DeathInfo.Cause) -> void:
	Global.root.world.bullet_spawner.make_bullet_local(spawn_pos, dir_pos, deviation, shooter, _speed, damage, cause)
	
@rpc("call_local")
func make_bullet_melee(pos: Vector3, rot: Vector3, target_name: StringName, shooter: StringName, damage: float) -> void:
	if target_name != "NONE":
		Global.root.world.bullet_spawner.make_melee_definite(pos, target_name, shooter, damage)
		return
	Global.root.world.bullet_spawner.make_melee(pos, rot, shooter, 105.0)

@rpc("any_peer", "call_local")
func change_to_team(t: Team) -> void:
	team = t
	team_changed_timer = 10

@rpc("any_peer", "call_local")
func set_perms(perm: Permissions) -> void:
	if permissions == Permissions.Host:
		Global.root.world.console.con_print_remote.rpc("Attention: Somebody may have caused an exploit or hacked to try change the host's permissions!", StringName("ALL"))
		return
	permissions = perm

func screenshot() -> void:
	screenshotting = true
	$"Head/Cam/posterizer LAYER 2".hide()
	$HUDVP/crosshair.hide()
	await get_tree().create_timer(0.2).timeout
	var image = get_viewport().get_texture().get_image()
	image.resize(540, 540)
	image.save_png("res://screenshot2.png")
	print("Screenshot saved!")
	screenshotting = false
	$"Head/Cam/posterizer LAYER 2".show()
	$HUDVP/crosshair.show()
