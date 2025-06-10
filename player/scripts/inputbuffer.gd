extends Resource
class_name InputBuffer

#movement
var forward: float = 0.0
var back: float = 0.0
var left: float = 0.0
var right: float = 0.0
var jump: bool = false
var crouch: bool = false

var attack_light: bool = false
var attack_light_const: bool = false
var attack_heavy: bool = false
var reload: bool = false
var switch: bool = false

func set_wasd(w: float, a: float, s: float, d: float) -> void:
	forward = w
	left = a
	back = s
	right = d
	
func get_wasd() -> Vector2:
	return Vector2(right - left, back - forward)
