extends CanvasLayer
class_name Console

#TODO: Press up or down to cycle between previous commands

@onready var history: Label = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/history
@onready var command: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/command

var active: bool = false

@export var accepted_commands: Array[StringName]
@export var command_desc: Array[String]

@onready var cont: PanelContainer = $PanelContainer

func _ready() -> void:
	cont.focus_mode = Control.FOCUS_ALL
	command.focus_mode = Control.FOCUS_ALL

func command_focus() -> void:
	command.grab_focus()
	command.text = command.text.replace("`", "")
	command.select_all()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("console"):
		cont.visible = !cont.visible
		if cont.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			command.editable = cont.visible
			await get_tree().process_frame
			command_focus()
		elif Global.root.world != null:
			command.editable = cont.visible
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			command.editable = cont.visible
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	active = cont.visible

@rpc("authority", "call_local")
func con_print_remote(data: String, to: StringName) -> void:
	if to != Global.root.world.player.name && to != "ALL" : return
	history.text += data + "\n"
	
func con_print(data: String) -> void:
	history.text += data + "\n"

func _on_command_text_submitted(new_text: String) -> void:
	var keywords: Array[String] = [""]
	var idx: int = 0
	for i in new_text:
		if i != " ":
			keywords[idx] += i
		else:
			idx += 1
			keywords.append("")
	var st_name: StringName = keywords[0]
	var valid: bool = false
	for i: StringName in accepted_commands:
		if st_name == i:
			con_print(new_text)
			call(st_name, keywords)
			valid = true
			break
	if !valid:
		con_print("COMMAND: '" + new_text + "' NOT RECOGNISED")
	
	await get_tree().process_frame
	command_focus()

func noclip(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.set_noclip.rpc(keywords[1], keywords[2], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func hurt(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.console_request_damage(keywords[1], float(keywords[2]), Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func ultrasupermeditationmaximum(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.set_godmode.rpc(keywords[1], keywords[2], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func exitworld(_keywords: Array[String]) -> void:
	Global.root.stop_world()
	
func hostinfo(_keywords: Array[String]) -> void:
	if Global.root.world.is_multiplayer_authority():
		con_print(Global.root.world.upnp.query_external_address() + ":" + str(Global.root.PORT))
	else:
		con_print("You are not the host. Host info may be available for members in a future update.")

func help(_keywords: Array[String]) -> void:
	var final_output: String = "LIST OF ALL COMMANDS:"
	for i in range(0, accepted_commands.size()):
		var add: String = "\n" + "\n"
		add += accepted_commands[i]
		add += " - "
		add += command_desc[i]
		final_output += add
	final_output += "\n" + "\nNOTES:\nFor true/false arguments, only typing 'true' will set the value to true. Any other text will set it to false."
	con_print(final_output)

func permissions(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.change_perms.rpc(keywords[1], keywords[2], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func team(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.change_team.rpc(keywords[1], keywords[2], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func kick(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.kick_player.rpc(keywords[1], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func mute(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.set_mute_local(keywords[1], keywords[2])
	else:
		con_print("ERROR: no world loaded")

func mute_global(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.set_mute_global.rpc(keywords[1], keywords[2], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func friendly_fire(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.set_friendly_fire.rpc(keywords[1], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func set_gravity(keywords: Array[String]) -> void:
	if Global.root.world != null:
		Global.root.world.set_gravity.rpc(keywords[1], Global.root.world.player.name)
	else:
		con_print("ERROR: no world loaded")

func exit_game(keywords: Array[String]) -> void:
	Global.exit()
