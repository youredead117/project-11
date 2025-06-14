extends CanvasLayer
class_name MainMenu

@onready var host_button = $PanelContainer/MarginContainer/VBoxContainer/host

var selected_map: MapItem

var map_list: MapsList

func _ready() -> void:
	map_list = load("res://scenes/menu/mapinfo/MapList.tres")
	select_map(map_list.maps[0])
	Steam.lobby_match_list.connect(on_lobby_match_list)
	_on_refresh_pressed()
	show_maps()

func show_maps() -> void:
	for i in map_list.maps:
		var ui: MapInfoUI = load("res://scenes/menu/mapinfo/map_info_ui.tscn").instantiate()
		ui.map_item = i
		$PanelContainer/MarginContainer/VBoxContainer/maps/VBoxContainer.add_child(ui)

func _on_refresh_pressed() -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func on_lobby_match_list(lobbies) -> void:
	var amt_lobbies: int = 0
	
	for i: Control in $PanelContainer/MarginContainer/VBoxContainer/lobbies/VBoxContainer.get_children():
		i.queue_free()
	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "lobby_name_PROJECT11")
		if lobby_name.begins_with("PROJECT11: "):
			amt_lobbies += 1
			var member_count: int = Steam.getNumLobbyMembers(lobby)
			var max_members: int = Steam.getLobbyMemberLimit(lobby)
			
			var map_name: String = Steam.getLobbyData(lobby, "map_name")
			var mode_name: String = "FFA Deathmatch" #Steam.getLobbyData(lobby, "mode_name")
			
			
			var lobby_info: LobbyInfo = load("res://scenes/menu/lobby_info.tscn").instantiate()
			$PanelContainer/MarginContainer/VBoxContainer/lobbies/VBoxContainer.add_child(lobby_info)
			lobby_info.set_info(lobby_name, member_count, max_members, lobby, map_name, mode_name)
	
	$PanelContainer/MarginContainer/VBoxContainer/LobbiesTitle.text = "LOBBIES ONLINE: " + str(amt_lobbies)
	


func _on_host_pressed() -> void:
	Global.make_steam_lobby()

func select_map(map_item: MapItem) -> void:
	host_button.text = "HOST " + map_item.map_name
	selected_map = map_item


func _on_exit_pressed() -> void:
	Global.exit()
