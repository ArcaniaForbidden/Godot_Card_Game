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
		"attack_speed": 0.8,
		"equipment_slots": ["helmet", "chestplate", "leggings", "boots", "weapon", "shield", "accessory1", "accessory2", "accessory3", "accessory4"]
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
	"forest": {
		"card": preload("res://Images/green_card.png"),
		"sprite": preload("res://Images/forest.png"),
		"card_type": "resource",
		"display_name": "Forest"
	},
	"house": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/house.png"),
		"card_type": "building",
		"display_name": "House",
		"health": 25,
		"attack": 0,
		"armor": 0,
		"attack_speed": 0
	},
	"lumber_camp": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/lumber_camp.png"),
		"card_type": "building",
		"display_name": "Lumber Camp",
		"health": 25,
		"attack": 0,
		"armor": 0,
		"attack_speed": 0
	},
	"quarry": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Quarry",
		"health": 25,
		"attack": 0,
		"armor": 0,
		"attack_speed": 0
	},
	"wooden_spear": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/wooden_spear.png"),
		"card_type": "equipment",
		"slot": "weapon",
		"display_name": "Wooden Spear",
		"description": "A crude spear carved from wood. Increases attack slightly, but attacks slower.",
		"stats": {
			"add": {
				"attack": 1
			},
			"mul": {
				"attack_speed": 0.9  # 10% slower attacks
			}
		}
	}
}
