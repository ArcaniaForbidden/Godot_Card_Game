extends Node
class_name CardDatabase

static var card_database = {
	"peasant": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Animations/peasant.tres"),
		"animated": true,
		"card_type": "unit",
		"display_name": "Peasant",
		"stats": {
			"health": 10,
			"attack": 1,
			"armor": 0,
			"attack_speed": 0.8
		},
	},
	"wolf": {
		"card": preload("res://Images/enemy_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "enemy",
		"display_name": "Wolf",
		"stats": {
			"health": 4,
			"attack": 1,
			"armor": 0,
			"attack_speed": 1.2
		}
	},
	"tree": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/tree.png"),
		"card_type": "resource",
		"display_name": "Tree"
	},
	"rock": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Rock"
	},
	"water_deposit": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Water Deposit"
	},
	"iron_deposit": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Iron Deposit"
	},
	"copper_deposit": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Copper Deposit"
	},
	"gold_deposit": {
		"card": preload("res://Images/basic_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Gold Deposit"
	},
	"soil": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/stone.png"),
		"card_type": "material",
		"display_name": "Soil"
	},
	"stone": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/stone.png"),
		"card_type": "material",
		"display_name": "Stone"
	},
	"wood": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Wood"
	},
	"iron_ore": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Iron Ore"
	},
	"copper_ore": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Copper Ore"
	},
	"gold_ore": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Gold Ore"
	},
	"plank": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/plank.png"),
		"card_type": "material",
		"display_name": "Plank"
	},
	"brick": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/brick.png"),
		"card_type": "material",
		"display_name": "Brick"
	},
	"house": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/house.png"),
		"card_type": "building",
		"display_name": "House",
		"stats": {
			"health": 25,
			"attack": 0,
			"armor": 0,
			"attack_speed": 0
		}
	},
	"lumber_camp": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/lumber_camp.png"),
		"card_type": "building",
		"display_name": "Lumber Camp",
		"stats": {
			"health": 25,
			"attack": 0,
			"armor": 0,
			"attack_speed": 0
		}
	},
	"quarry": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Quarry",
		"stats": {
			"health": 25,
			"attack": 0,
			"armor": 0,
			"attack_speed": 0
		}
	},
	"iron_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Iron Mine",
		"stats": {
			"health": 25,
			"attack": 0,
			"armor": 0,
			"attack_speed": 0
		}
	},
	"copper_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Copper Mine",
		"stats": {
			"health": 25,
			"attack": 0,
			"armor": 0,
			"attack_speed": 0
		}
	},
	"gold_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Gold Mine",
		"stats": {
			"health": 25,
			"attack": 0,
			"armor": 0,
			"attack_speed": 0
		}
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
	},
	"iron_spear": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "equipment",
		"slot": "weapon",
		"display_name": "Iron Spear",
		"description": "A bigger spear",
		"stats": {
			"add": {
				"attack": 2
			},
			"mul": {
				"attack_speed": 1.0  # 10% slower attacks
			}
		}
	},
	"plains": {
		"card": preload("res://Images/green_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "location",
		"display_name": "Plains"
	},
	"forest": {
		"card": preload("res://Images/green_card.png"),
		"sprite": preload("res://Images/forest.png"),
		"card_type": "location",
		"display_name": "Forest"
	},
	"mountain": {
		"card": preload("res://Images/green_card.png"),
		"sprite": preload("res://Images/forest.png"),
		"card_type": "location",
		"display_name": "Mountain"
	},
}
