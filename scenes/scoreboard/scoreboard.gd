extends CanvasLayer
class_name ScoreBoard

enum INDEX{
	PLAYERS,
	KILLS,
	ASSISTS,
	DEATHS,
	DAMAGE,
	SCORE,
	SIZE
}

var all_data: Array[ScoreBoardElement]

@onready var cont: PanelContainer = $PanelContainer

func _process(_delta: float) -> void:
	if Input.is_action_pressed("tab"):
		visible = true
	else:
		visible = false

func make_new_element(n: StringName) -> void:
	var element: ScoreBoardElement = ScoreBoardElement.new()
	element.name = n
	all_data.append(element)
	
func remove_element(n: StringName) -> void:
	var element = find_player_element(n)
	element.node.queue_free()
	all_data.erase(element)

func serialize_data() -> Array[Array]:
	var arr: Array[Array] = []
	for i: ScoreBoardElement in all_data:
		arr.append(i.serialized())
	return arr

func update_full_sb(arr: Array[Array]) -> void:
	for i: ScoreBoardElement in all_data:
		if i.node:
			i.node.queue_free()
	all_data.clear()
	for i: int in range(0, arr.size()):
		var el: ScoreBoardElement = ScoreBoardElement.new()
		all_data.append(el)
		el.set_data(arr[i])
		el.node = load("res://scenes/scoreboard/score_board_row.tscn").instantiate()
		$PanelContainer/MarginContainer/VBoxContainer.add_child(el.node)
		el.update_node()

	
func update_value(section: INDEX, player_name: StringName, value) -> void:
	var element: ScoreBoardElement = find_player_element(player_name)
	if element == null:
		printerr("FAILED TO FIND PLAYER IN SCOREBOARD, PLAYER NAMED '" + player_name + "'")
		return
	
	if element.all_vals[section] is float || element.all_vals[section] is int:
		element.all_vals[section] += value
	else:
		element.all_vals[section] = value
	element.update_node()

func find_player_element(n: StringName) -> ScoreBoardElement:
	for i: ScoreBoardElement in all_data:
		if i.name == n:
			return i
	return null
