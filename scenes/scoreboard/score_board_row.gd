extends HBoxContainer
class_name ScoreBoardRow

#[name, kills, assists, deaths, damage, score]

var player_id: int

var has_setup: bool = false

@onready var labels: Array[Label] = [	$"Player--",
										$Kills,
										$Assists,
										$Deaths,
										$Damage,
										$Score]

func _ready() -> void:
	Steam.avatar_loaded.connect(_on_loaded_avatar)

func setup(id: int) -> void:
	player_id = id
	Steam.getPlayerAvatar(Steam.AVATAR_SMALL, player_id)

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	if user_id != player_id: return
	Steam.avatar_loaded.disconnect(_on_loaded_avatar)
	
	# Create the image and texture for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	
	# Optionally resize the image if it is too large
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	
	# Apply the image to a texture
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	
	# Set the texture to a Sprite, TextureRect, etc.
	$icon.texture = avatar_texture


func update(vals: ScoreBoardElement) -> void:
	
	var pl: Player = Global.root.world.find_player(vals.name)
	if pl != null:
		if !has_setup:
			has_setup = true
			setup(pl.steam_player_id)
		theme.set("Label/colors/font_color", Player.TEAM_COLOR[pl.team])
	else:
		theme.set("Label/colors/font_color", Color.WHITE)
	for i: int in range(0, labels.size()):
		if vals.all_vals[i] is StringName:
			
			if pl != null:
				labels[i].text = pl.username + "123456789"
			else:
				labels[i].text = str(vals.all_vals[i])
				
		else:
			labels[i].text = str(vals.all_vals[i])
			
		var amt_spaces: int = str(labels[i].name).length() - labels[i].text.length()
		if amt_spaces < 0:
			if i == 0:
				var base_font_size: int = 16
				var overshoot_chars: int = -amt_spaces
				var max_chars: int = 20  # For example
				var shrink_rate: float = Global.root.text_shrink_rate  # How much to reduce per extra character

				var new_font_size: float = base_font_size / (1.0 + (overshoot_chars * shrink_rate))
				new_font_size = clamp(new_font_size, 8, base_font_size)  # Avoid shrinking too much
				
				labels[i].label_settings.font_size = new_font_size
		else:
			for j: int in range(0, amt_spaces):
				labels[i].text += " "
