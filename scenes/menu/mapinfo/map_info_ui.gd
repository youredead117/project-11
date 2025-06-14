extends VBoxContainer
class_name MapInfoUI

@onready var text_rect: TextureRect = $TextureRect
@onready var button: Button = $Button

var map_item: MapItem

func _ready() -> void:
	text_rect.texture = map_item.image
	button.text = map_item.map_name
	button.tooltip_text = map_item.map_description

func _on_button_pressed() -> void:
	Global.root.menu.select_map(map_item)

func _process(delta: float) -> void:
	if Global.root.menu.selected_map == map_item:
		button.theme.set("Button/colors/font_color", Color.AQUA)
		button.theme.set("Button/colors/font_focus_color", Color.AQUA)
	else:
		button.theme.set("Button/colors/font_color", Color.DIM_GRAY)
		button.theme.set("Button/colors/font_focus_color", Color.DIM_GRAY)
