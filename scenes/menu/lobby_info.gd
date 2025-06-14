extends HBoxContainer
class_name LobbyInfo

@onready var name_label: Label = $Name
@onready var players_label: Label = $playerCount
@onready var map_label: Label = $Map
@onready var mode_label: Label = $Mode
@onready var connect_button: Button = $connect

var lobby_id: int

func set_info(lobby_name: String, players: int, players_max: int, id: int, map_name: String, mode_name: String) -> void:
	name_label.text = lobby_name
	players_label.text = str(players) + "/" + str(players_max) + " Players"
	map_label.text = map_name
	mode_label.text = mode_name
	lobby_id = id
	connect_button.connect("pressed", connect_lobby)

func connect_lobby() -> void:
	Steam.joinLobby(lobby_id)
