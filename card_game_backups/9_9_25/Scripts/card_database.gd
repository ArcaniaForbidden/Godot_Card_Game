extends Node
class_name CardDatabase

static var card_database := {
	"villager": {
		"sprite": preload("res://Images/villager.png"),
		"card_type": "unit",
		"display_name": "Villager",
		"health": 10,
		"attack": 2,
		"armor": 0,
		"attack_speed": 1.0
	},
	"rock": {
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Rock"
	},
	"wolf": {
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "enemy",
		"display_name": "Wolf",
		"health": 5,
		"attack": 1,
		"armor": 0,
		"attack_speed": 1.5
	},
	"stone": { 
		"sprite": preload("res://Images/stone.png"),
		"card_type": "material",
		"display_name": "Stone"
	},
	"tree": {
		"sprite": preload("res://Images/tree.png"),
		"card_type": "resource",
		"display_name": "Tree"
	},
	"wood": {
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Wood"
	},
}
