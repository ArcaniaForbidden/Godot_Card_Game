extends Node
class_name CardDatabase

static var card_database = {
	"villager": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/villager.png"),
		"card_type": "unit",
		"display_name": "Villager",
		"health": 10,
		"attack": 1,
		"armor": 0,
		"attack_speed": 0.8
	},
	"boulder": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Boulder"
	},
	"wolf": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "enemy",
		"display_name": "Wolf",
		"health": 4,
		"attack": 1,
		"armor": 0,
		"attack_speed": 1.2
	},
	"stone": { 
		"card": preload("res://Images/basic_card.png"),
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
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Wood"
	},
}
