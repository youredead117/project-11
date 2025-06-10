extends CanvasLayer
class_name MainMenu

@onready var address_entry: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/LineEdit
@onready var port_entry: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/PORT

func _ready() -> void:
	Steam.lobby_match_list.connect(on_lobby_match_list)
	_on_refresh_pressed()

func _on_test_level_0_pressed() -> void:
	Global.root.load_test_level()


func _on_qodot_level_1_pressed() -> void:
	multiplayer.multiplayer_peer = Global.root.enet_peer
	Global.make_steam_lobby()


func _on_refresh_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func on_lobby_match_list(lobbies) -> void:
	for i: Control in $PanelContainer/MarginContainer/VBoxContainer/lobbies/VBoxContainer.get_children():
		i.queue_free()
	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		var member_count: int = Steam.getNumLobbyMembers(lobby)
		
		var lobby_info: LobbyInfo = load("res://scenes/menu/lobby_info.tscn").instantiate()
		$PanelContainer/MarginContainer/VBoxContainer/lobbies/VBoxContainer.add_child(lobby_info)
		lobby_info.set_info(lobby_name, member_count, 8, lobby)
