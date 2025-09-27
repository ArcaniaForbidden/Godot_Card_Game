extends Node2D
class_name MapManager

# Define the play area rectangle for clamping
var map_rect: Rect2

func _ready():
	# Use the sprite size or manually set it
	var map_sprite = $MainIslandSprite2D
	if map_sprite:
		map_rect = Rect2(map_sprite.global_position - map_sprite.texture.get_size() / 2, map_sprite.texture.get_size())
