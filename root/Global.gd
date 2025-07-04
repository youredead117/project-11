extends Node

const PORT = 9888

var root: Root
@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var util: Utility = Utility.new()

var previous_connected_address: String = ""

var steam_id: int = 0
var steam_username: String = ""
var steam_lobby_id: int

var lobby_created: bool = false

var host: bool = false

func _init() -> void:
	OS.set_environment("SteamAppID", "480")
	OS.set_environment("SteamGameID", "480")

func _ready() -> void:
	Steam.steamInitEx()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_created.connect(_on_lobby_made)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
func _process(delta: float) -> void:
	Steam.run_callbacks()

func _on_lobby_made(connect: int, lobby_id: int) -> void:
	steam_lobby_id = lobby_id
	Steam.setLobbyType(lobby_id, Steam.LobbyType.LOBBY_TYPE_PUBLIC)
	Steam.setLobbyData(lobby_id, "lobby_name_PROJECT11", "PROJECT11: " + Steam.getPersonaName())
	Steam.setLobbyData(lobby_id, "map_name", root.menu.selected_map.map_name)
	Steam.setLobbyData(lobby_id, "mode_name", "MODE")
	Steam.setLobbyJoinable(lobby_id, true)
	host = true

func _on_lobby_join_requested(lobby_id: int, friend_id: int) -> void:
	Steam.joinLobby(lobby_id)
	
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		if host:
			Global.root.network_peer.create_host(Global.PORT)
		else:
			var map_name: String = Steam.getLobbyData(lobby_id, "map_name")
			var map: MapItem = null
			
			for i: MapItem in Global.root.menu.map_list.maps:
				if i.map_name == map_name:
					map = i
					break
			
			if !map:
				print("NO MAP FOUND")
				return
			
			root.menu.selected_map = map
			Global.root.network_peer.create_client(Steam.getLobbyOwner(lobby_id), Global.PORT)

		multiplayer.multiplayer_peer = Global.root.network_peer

		var uid: int = multiplayer.get_unique_id()

		root.load_level()
		root.world.add_player(uid, false)

		if host:
			Global.root.world.connect_peer_join_signal()

func make_steam_lobby() -> void:
	if lobby_created: return
	lobby_created = true
	host = true
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 8)
	

func exit() -> void:
	cleanup_steam_multiplayer()
	get_tree().quit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		exit()

func cleanup_steam_multiplayer():
	Steam.leaveLobby(Global.steam_lobby_id)

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
