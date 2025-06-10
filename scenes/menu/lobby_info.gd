extends HBoxContainer
class_name LobbyInfo

@onready var name_label: Label = $Name
@onready var info_label: Label = $Info
@onready var connect_button: Button = $connect

var lobby_id: int

func set_info(lobby_name: String, players: int, players_max: int, id: int) -> void:
	name_label.text = lobby_name
	info_label.text = str(players) + "/" + str(players_max) + " Players"
	lobby_id = id
	connect_button.connect("pressed", connect_lobby)

func connect_lobby() -> void:
	Steam.joinLobby(lobby_id)
