extends Node3D
class_name World

var player: Player

@onready var qodot_map: QodotMap = $QodotMap
var map_info: MapItem

@onready var environment = $WorldEnvironment.environment
@export var environment_setter: Environment

var players: Array[Player]

@onready var console: Console = Global.root.console

#world rules / behaviour
var rules: WorldRules = WorldRules.new()

@onready var scoreboard: ScoreBoard = load("res://scenes/scoreboard/scoreboard.tscn").instantiate()
@onready var bullet_spawner: BulletSpawner = $BulletSpawner
var player_spawners: Array[PlayerSpawner]

var server_uptime: float = 0.0
var round_time_elapsed: float = 0.0

func _ready() -> void:
	add_child(scoreboard)
	
func _physics_process(delta: float) -> void:
	server_uptime += delta
	round_time_elapsed += delta
	
@rpc("any_peer", "call_remote")
func request_sync_time() -> void:
	sync_time.rpc(server_uptime, round_time_elapsed)
	
@rpc("authority", "call_remote")
func sync_time(server: float, round: float) -> void:
	server_uptime = server
	round_time_elapsed = round
	
@rpc("any_peer", "call_local")
func send_players_list() -> void:
	var usernames: Array[String]
	var node_names: Array[StringName]
	for i: Player in players:
		usernames.append(i.username)
		node_names.append(i.name)
	update_players_list.rpc(usernames, node_names)

func player_joined(n: StringName) -> void:
	if !is_multiplayer_authority(): return
	
	scoreboard.make_new_element(n)

func player_left(n: StringName) -> void:
	if !is_multiplayer_authority(): return
	
	scoreboard.remove_element(n)
	send_scoreboard(scoreboard)

func player_died(died: StringName, killer: StringName, assister: StringName) -> void:
	if !is_multiplayer_authority(): return
	
	update_scoreboard(ScoreBoard.INDEX.DEATHS, died, 1)
	if killer != "NONE":
		update_scoreboard(ScoreBoard.INDEX.KILLS, killer, 1)
	if assister != "NONE":
		update_scoreboard(ScoreBoard.INDEX.ASSISTS, assister, 1)

@rpc("authority", "call_local")
func update_players_list(usernames: Array[String], node_names: Array[StringName]) -> void:
	for pl: Player in players:
		for i in range(0, node_names.size()):
			if node_names[i] == pl.name:
				pl.username = usernames[i]
				break

@rpc("authority", "call_remote")
func update_world_rules(arr: Array) -> void:
	rules.replace_rules(arr)

@rpc("any_peer", "call_local")
func send_world_rules() -> void:
	if !is_multiplayer_authority(): return
	update_world_rules.rpc(rules.serialized())

@rpc("any_peer", "call_local")
func request_scoreboard() -> void:
	send_scoreboard(scoreboard)

func send_scoreboard(sb: ScoreBoard) -> void:
	if !is_multiplayer_authority(): return
	recieve_scoreboard.rpc(sb.serialize_data())
	
@rpc("authority", "call_local")
func recieve_scoreboard(encoded_sb: Array[Array]) -> void:
	scoreboard.update_full_sb(encoded_sb)

@rpc("authority", "call_local")
func update_scoreboard(idx: ScoreBoard.INDEX, n: StringName, val) -> void:
	scoreboard.update_value(idx, n, val)

func _process(delta: float) -> void:
	environment.fog_light_color = lerp(environment.fog_light_color, environment_setter.fog_light_color, 0.01)
	environment.fog_density = lerp(environment.fog_density, environment_setter.fog_density, 0.01)
	environment.fog_light_energy = lerp(environment.fog_light_energy, environment_setter.fog_light_energy, 0.01)

func add_player(peer_id, is_host: bool = false):
	var pl = load("res://player/player.tscn").instantiate()
	pl.name = str(peer_id)
	var spawner: PlayerSpawner = player_spawners[Global.rng.randi_range(0, player_spawners.size()-1)]
	var pos: Vector3 = spawner.get_spawn_pos()
	if pos == Vector3.INF:
		pos = Vector3(0.0, 5.0, 0.0)
	add_child(pl)
	pl.global_position = pos

func disconnect_player(peer_id: int) -> void:
	var pl: Player = get_node_or_null(str(peer_id))
	if pl:
		console.con_print_remote.rpc(pl.username + " left the game.", "ALL")
		players.erase(pl)
		pl.queue_free()
		player_left(str(peer_id))
		
func random_spawn_player(pl: Player):
	var spawner: PlayerSpawner = player_spawners[Global.rng.randi_range(0, player_spawners.size()-1)]
	var pos: Vector3 = spawner.get_spawn_pos()
	if pos == Vector3.INF:
		pos = Vector3(0.0, 5.0, 0.0)
	pl.global_position = pos

func connect_peer_join_signal() -> void:
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(disconnect_player)
	
func find_player(n: StringName) -> Player:
	for i in players:
		if i.name == n:
			return i
	printerr("NO PLAYER FOUND WITH NAME: " + n)
	print_stack()
	return null

@rpc("authority", "call_local")
func request_damage(victim_name: StringName, damage: float, pos: Vector3 = Vector3.INF, from_player: StringName = "", cause: DeathInfo.Cause = DeathInfo.Cause.Map) -> void:
	var pl: Player = find_player(victim_name)
	if is_instance_valid(pl):
		pl.hurt(damage, pos, from_player, cause)

@rpc("any_peer", "call_local")
func request_damage_admin(victim_name: StringName, damage: float, from_player: StringName, pos: Vector3 = Vector3.INF) -> void:
	var pl: Player = find_player(victim_name)
	if is_instance_valid(pl):
		pl.hurt(damage, pos, from_player, DeathInfo.Cause.Command)
		
@rpc("any_peer", "call_local")
func heal(pl_name: StringName) -> void:
	find_player(pl_name).heal()
		
func check_perms(n: StringName) -> Player.Permissions:
	for i: Player in players:
		if i.name == n:
			return i.permissions
	return Player.Permissions.NONE

@rpc("any_peer", "call_local")
func set_noclip(usr: String, val: String, from_player: StringName) -> void:
	
	var perms: Player.Permissions = check_perms(from_player)
	if perms < Player.Permissions.Admin:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
		
	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
		
	for i: Player in players:
		if i.username == usr:
			i.set_noclip(Global.util.str_to_bool(val))
			console.con_print_remote.rpc("Command success", from_player)
			return
			
	console.con_print_remote.rpc("ERROR: Player not found.", from_player)
	
@rpc("any_peer", "call_local")
func set_godmode(usr: String, val: String, from_player) -> void:
	
	var perms: Player.Permissions = check_perms(from_player)
	if perms < Player.Permissions.Admin:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
		
	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
				
	for i: Player in players:
		if i.username == usr:
			i.set_godmode(Global.util.str_to_bool(val))
			console.con_print_remote.rpc("Command success", from_player)
			return
			
	console.con_print_remote.rpc("ERROR: Player not found.", from_player)

func console_request_damage(usr: String, val: float, from_player: StringName) -> void:
	var perms: Player.Permissions = check_perms(from_player)
	if perms != Player.Permissions.Admin && perms != Player.Permissions.Host:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
		
	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
				
	for i: Player in players:
		if i.username == usr:
			request_damage_admin.rpc(i.name, val, from_player, Vector3.INF)
			console.con_print("Command success")
			return
	console.con_print("ERROR: Player not found.")

@rpc("any_peer", "call_local")
func change_perms(usr: String, val: String, from_player: StringName) -> void:
	
	var perms: Player.Permissions = check_perms(from_player)
	if perms < Player.Permissions.Admin:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
		
	var perm: Player.Permissions = Player.Permissions.NONE
	var v: String = val.to_lower()
	
	if v == "admin":
		perm = Player.Permissions.Admin
	elif v == "mod" || v == "moderator":
		perm = Player.Permissions.Mod
	elif v == "member":
		perm = Player.Permissions.Member
	else:
		console.con_print_remote.rpc("No such permission exists.", from_player)
		return
		
	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
				
	for i: Player in players:
		if i.username == usr:
			
			if i.permissions == Player.Permissions.Host:
				console.con_print_remote.rpc("The target is the host, you cannot change their permissions.", from_player)
				return
				
			i.set_perms.rpc(perm)
			console.con_print_remote.rpc("Command success", from_player)
			return
			
	console.con_print_remote.rpc("ERROR: Player not found", from_player)

@rpc("any_peer", "call_local")
func kick_player(usr: String, from_player: StringName) -> void:
	if check_perms(from_player) < Player.Permissions.Mod:
		return
	
	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
				
	if is_multiplayer_authority():
		var to_kick: StringName = ""
		for i: Player in players:
			if i.username == usr:
				to_kick = i.name
		Global.root.enet_peer.disconnect_peer(int(to_kick))

@rpc("any_peer", "call_local")
func change_team(usr: String, team: String, from_player: StringName) -> void:
	
	if check_perms(from_player) < Player.Permissions.Mod:
		console.con_print("ERROR: You do not have the permissions for this command.")
		return

	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
				
	var t: Player.Team = Global.util.get_team_from_string(team)
	for i: Player in players:
		if i.username == usr:
			i.change_to_team.rpc(t)
			console.con_print("Command success")
			await get_tree().create_timer(0.1).timeout
			send_scoreboard(scoreboard)
			return
	console.con_print("ERROR: Player not found")

@rpc("any_peer", "call_local")
func set_friendly_fire(val: String, from_player: StringName) -> void:
	#sets friendly fire state of the world
	var perms: Player.Permissions = check_perms(from_player)
	if perms < Player.Permissions.Admin:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
		
	rules.friendly_fire = Global.util.str_to_bool(val)
	console.con_print_remote.rpc("Command success", from_player)
	
@rpc("any_peer", "call_local")
func set_gravity(val: String, from_player: StringName) -> void:
	#sets the gravity constant of the world
	var perms: Player.Permissions = check_perms(from_player)
	if perms < Player.Permissions.Admin:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
		
	if !val.is_valid_float():
		console.con_print_remote.rpc("ERROR: A valid number was not entered", from_player)
		return
		
	rules.gravity = float(val)
	console.con_print_remote.rpc("Command success", from_player)

@rpc("any_peer", "call_local")
func set_mute_global(usr: String, val: String, from_player: StringName):
	#muting for whole server, only allowed if you are mod or above.
	var perms: Player.Permissions = check_perms(from_player)
	if perms < Player.Permissions.Mod:
		console.con_print_remote.rpc("ERROR: You do not have the permissions for this command.", from_player)
		return
	
	if usr.to_lower() == "me":
		for i: Player in players:
			if i.name == from_player:
				usr = i.username
				
	for i: Player in players:
		if i.username == usr:
			i.muted_global = Global.util.str_to_bool(val)
			console.con_print_remote.rpc("Command success")
			return
			
	console.con_print_remote.rpc("ERROR: Player not found")

func set_mute_local(usr: String, val: String):
	#muting for local/client, does not need perms to change, however only affects that client.
	for i: Player in players:
		if i.username == usr:
			i.muted_local = Global.util.str_to_bool(val)
			console.con_print("Command success")
			return
			
	console.con_print("ERROR: Player not found")
