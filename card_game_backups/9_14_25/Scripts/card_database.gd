extends Node
class_name CardDatabase

static var card_database = {
	"peasant": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/peasant.png"),
		"card_type": "unit",
		"display_name": "Peasant",
		"health": 10,
		"attack": 1,
		"armor": 0,
		"attack_speed": 0.8
	},
	"rock": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Rock"
	},
	"wolf": {
		"card": preload("res://Images/enemy_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "enemy",
		"display_name": "Wolf",
		"health": 4,
		"attack": 1,
		"armor": 0,
		"attack_speed": 1.2
	},
	"stone": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/stone.png"),
		"card_type": "material",
		"display_name": "Stone"
	},
	"tree": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/tree.png"),
		"card_type": "resource",
		"display_name": "Tree"
	},
	"wood": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Wood"
	},
	"village": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/village.png"),
		"card_type": "unit",
		"display_name": "Village",
		"health": 50,
		"attack": 0,
		"armor": 1,
		"attack_speed": 0
	},
}
