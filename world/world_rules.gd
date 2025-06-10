extends Resource
class_name WorldRules

enum INDEX{
	GRAVITY,
	FRIENDLY_FIRE,
	SIZE
}

var gravity: float = 9.81
var friendly_fire: bool = true

func serialized() -> Array:
	return [gravity, friendly_fire]
	
func replace_rules(arr: Array) -> void:
	gravity = arr[INDEX.GRAVITY]
	friendly_fire = arr[INDEX.FRIENDLY_FIRE]
