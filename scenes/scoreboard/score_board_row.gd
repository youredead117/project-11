extends HBoxContainer
class_name ScoreBoardRow

#[name, kills, assists, deaths, damage, score]

var player_id: int

var has_setup: bool = false

@onready var labels: Array[Label] = [	$Player,
										$Kills,
										$Assists,
										$Deaths,
										$Damage,
										$Score]

func _ready() -> void:
	Steam.avatar_loaded.connect(_on_loaded_avatar)

func setup(id: int) -> void:
	player_id = id
	await get_tree().create_timer(0.1).timeout
	Steam.getPlayerAvatar(2, player_id)

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PoolByteArray) -> void:
	
	print("Avatar for user: %s" % user_id)
	print("Size: %s" % avatar_size)
	
	# Create the image and texture for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	
	# Optionally resize the image if it is too large
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	
	# Apply the image to a texture
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	
	# Set the texture to a Sprite, TextureRect, etc.
	$icon.texture = avatar_texture
	Steam.avatar_loaded.disconnect(_on_loaded_avatar)


func update(vals: ScoreBoardElement) -> void:
	if !has_setup:
		has_setup = true
		setup(int(vals.name))
	
	var pl: Player = Global.root.world.find_player(vals.name)
	if pl != null:
		theme.set("Label/colors/font_color", Player.TEAM_COLOR[pl.team])
	else:
		theme.set("Label/colors/font_color", Color.WHITE)
	for i: int in range(0, labels.size()):
		if vals.all_vals[i] is StringName:
			
			if pl != null:
				labels[i].text = pl.username
			else:
				labels[i].text = str(vals.all_vals[i])
				
		else:
			labels[i].text = str(vals.all_vals[i])
			
		var amt_spaces: int = str(labels[i].name).length() - labels[i].text.length()
		for j: int in range(0, amt_spaces):
			labels[i].text += " "
