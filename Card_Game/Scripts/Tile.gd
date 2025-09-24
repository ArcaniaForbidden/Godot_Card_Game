extends Node2D
class_name Tile

var grid_pos: Vector2
var biome_type: String = "forest"
var is_explored: bool = false
var question_mark_card: Card = null

const BIOME_SPRITES = {
	#"forest": preload("res://Sprites/forest_tile.png"),
	#"desert": preload("res://Sprites/desert_tile.png"),
	#"swamp": preload("res://Sprites/swamp_tile.png"),
	"plains": preload("res://Images/tile_plains.png"),
	#"mountain": preload("res://Sprites/mountain_tile.png")
}

func _ready():
	if $TileSprite2D and BIOME_SPRITES.has(biome_type):
		$TileSprite2D.texture = BIOME_SPRITES[biome_type]

	# Make the question mark card an actual Card instance
	#question_mark_card = $QuestionMarkCard as Card
	#if question_mark_card:
		#question_mark_card.visible = false
		#question_mark_card.is_being_dragged = false   # Can't drag
		#question_mark_card.z_index = 50              # Below normal dragging z-index
		#question_mark_card.card_type = "question_mark"

func set_biome(biome: String) -> void:
	biome_type = biome
	if $TileSprite2D:
		$TileSprite2D.texture = BIOME_SPRITES.get(biome_type, null)

#func reveal_tile():
	#is_explored = true
	#if question_mark_card:
		#question_mark_card.visible = false
	## Optionally play a reveal animation here
#
#func show_question_mark():
	#if not is_explored and question_mark_card:
		#question_mark_card.visible = true
#
#func hide_question_mark():
	#if question_mark_card:
		#question_mark_card.visible = false
#
#func can_unit_enter() -> bool:
	## Only unit cards can enter
	#return true
