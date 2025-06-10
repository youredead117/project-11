extends Resource
class_name Utility

var true_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var repeat_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	repeat_rng.seed = 117

func _process() -> void:
	true_rng.seed = Time.get_unix_time_from_system()

func get_size_from_points(points: Array[Vector3]) -> Vector3:
	var bound_upper_size: Vector3 = Vector3.ZERO
	var bound_lower_size: Vector3 = Vector3.ZERO
	for i in points:
		if i.x > bound_upper_size.x:
			bound_upper_size.x = i.x
		elif i.x < bound_lower_size.x:
			bound_lower_size.x = i.x
		if i.y > bound_upper_size.y:
			bound_upper_size.y = i.y
		elif i.y < bound_lower_size.y:
			bound_lower_size.y = i.y
		if i.z > bound_upper_size.z:
			bound_upper_size.z = i.z
		elif i.z < bound_lower_size.z:
			bound_lower_size.z = i.z
	var size: Vector3 = Vector3.ZERO
	size = bound_upper_size - bound_lower_size
	return size

func str_to_bool(st: String) -> bool:
	if st.to_lower() == "true":
		return true
	return false

func get_team_from_string(st: String) -> Player.Team:
	st = st.to_lower()
	if st == "red":
		return Player.Team.RED
	if st == "blue":
		return Player.Team.BLUE
	if st == "green":
		return Player.Team.GREEN
	if st == "yellow":
		return Player.Team.YELLOW
	if st == "black":
		return Player.Team.BLACK
	if st == "white":
		return Player.Team.WHITE
	if st == "purple":
		return Player.Team.PURPLE
	if st == "brown":
		return Player.Team.BROWN
	return Player.Team.NONE
