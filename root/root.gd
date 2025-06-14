extends Node
class_name Root

var world: World = null
@onready var menu: MainMenu = $MainMenu
@onready var console: Console = $Console

var PORT: int = 9888 #NOT USED ANYMORE HAYYAYEHAEA
var host_ip: String = "NO_HOSTIP" #AND THIS TOO
var connect_ip: String = "" #AND THIS

var network_peer = SteamMultiplayerPeer.new()

@export var text_shrink_rate: float = 0.055

func _ready() -> void:
	Global.root = self
	
func load_level() -> void:
	if world != null: return
	world = menu.selected_map.map_scene.instantiate()
	world.set_multiplayer_authority(1)
	self.add_child(world)
	menu.queue_free()

func stop_world() -> void:
	if world != null:
		world.queue_free()
		menu = load("res://scenes/menu/menu.tscn").instantiate()
		add_child(menu)
		menu.show_previous_info()
