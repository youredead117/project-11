extends Control
class_name DeathPopup

func _ready() -> void:
	$PanelContainer.position.y = get_viewport_rect().size.y + 100.0

func setup_text(txt: String) -> void:
	$PanelContainer/MarginContainer/Label.text = txt
	
func _process(_delta: float) -> void:
	var pos: float = get_viewport_rect().size.y / 2.0
	pos -= (($PanelContainer.size.y / 2.0) - get_viewport_rect().size.y / 5.4)
	$PanelContainer.position.y = lerp($PanelContainer.position.y, pos, 0.02)
