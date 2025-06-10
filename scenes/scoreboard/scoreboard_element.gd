extends Resource
class_name ScoreBoardElement

var name: StringName
var username: String
var kills: int
var assists: int
var deaths: int
var damage: float
var score: int

var all_vals: Array = [name, kills, assists, deaths, damage, score]

var node: ScoreBoardRow

func serialized() -> Array:
	return [name, kills, assists, deaths, damage, score]

func set_data(arr: Array) -> void:
	name = arr[ScoreBoard.INDEX.PLAYERS]
	kills = arr[ScoreBoard.INDEX.KILLS]
	assists = arr[ScoreBoard.INDEX.ASSISTS]
	deaths = arr[ScoreBoard.INDEX.DEATHS]
	damage = arr[ScoreBoard.INDEX.DAMAGE]
	score = arr[ScoreBoard.INDEX.SCORE]

func update_node() -> void:
	if node is ScoreBoardRow:
		node.update(self)
