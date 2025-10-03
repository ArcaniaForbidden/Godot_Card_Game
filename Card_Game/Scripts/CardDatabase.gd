extends Node
class_name CardDatabase

static var card_database = {
	"peasant": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Animations/peasant.tres"),
		"animated": true,
		"card_type": "unit",
		"display_name": "Peasant",
		"stats": {"health": 10, "attack": 0, "armor": 0, "attack_speed": 0.8},
	},
	"wolf": {
		"card": preload("res://Images/enemy_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "enemy",
		"display_name": "Wolf",
		"stats": {"health": 4, "attack": 1, "armor": 0, "attack_speed": 1.2},
		#"loot_table": [
			#{ "subtype": "wood", "chance": 0.8 },
			#{ "subtype": "tree", "chance": 0.7 }
		#]
	},
	"tree": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/tree.png"),
		"card_type": "resource",
		"display_name": "Tree",
		"value": 1,
	},
	"rock": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Rock",
		"value": 1,
	},
	"iron_deposit": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/iron_deposit.png"),
		"card_type": "resource",
		"display_name": "Iron Deposit",
		"value": 1,
	},
	"copper_deposit": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/copper_deposit.png"),
		"card_type": "resource",
		"display_name": "Copper Deposit",
		"value": 1,
	},
	"gold_deposit": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/gold_deposit.png"),
		"card_type": "resource",
		"display_name": "Gold Deposit",
		"value": 1,
	},
	"soil": { 
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/soil.png"),
		"card_type": "resource",
		"display_name": "Soil",
		"value": 1,
	},
	"stone": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/stone.png"),
		"card_type": "material",
		"display_name": "Stone",
		"value": 1,
	},
	"wood": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/wood.png"),
		"card_type": "material",
		"display_name": "Wood",
		"value": 1,
	},
	"water": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/water.png"),
		"card_type": "material",
		"display_name": "Water",
		"value": 1,
	},
	"iron_ore": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/iron_ore.png"),
		"card_type": "material",
		"display_name": "Iron Ore",
		"value": 1,
	},
	"copper_ore": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/copper_ore.png"),
		"card_type": "material",
		"display_name": "Copper Ore",
		"value": 1,
	},
	"gold_ore": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/gold_ore.png"),
		"card_type": "material",
		"display_name": "Gold Ore",
		"value": 1,
	},
	"plank": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/plank.png"),
		"card_type": "material",
		"display_name": "Plank",
		"value": 5,
	},
	"brick": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/brick.png"),
		"card_type": "material",
		"display_name": "Brick",
		"value": 5,
	},
	"house": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/house.png"),
		"card_type": "building",
		"display_name": "House",
		"value": 5,
		"stats": {"health": 25}
	},
	"well": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/lumber_camp.png"),
		"card_type": "building",
		"display_name": "Well",
		"value": 5,
		"stats": {"health": 25}
	},
	"lumber_camp": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/lumber_camp.png"),
		"card_type": "building",
		"display_name": "Lumber Camp",
		"value": 5,
		"stats": {"health": 25}
	},
	"quarry": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Quarry",
		"value": 5,
		"stats": {"health": 25}
	},
	"iron_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Iron Mine",
		"value": 5,
		"stats": {"health": 25}
	},
	"copper_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Copper Mine",
		"value": 5,
		"stats": {"health": 25}
	},
	"gold_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/quarry.png"),
		"card_type": "building",
		"display_name": "Gold Mine",
		"value": 5,
		"stats": {"health": 25}
	},
	"wooden_spear": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/wooden_spear.png"),
		"card_type": "equipment",
		"slot": "weapon",
		"display_name": "Wooden Spear",
		"value": 1,
		"description": "A crude spear carved from wood. Increases attack slightly, but attacks slower.",
		"stats": {"add": {"attack": 1}, "mul": {"attack_speed": 0.9}}
	},
	"iron_spear": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "equipment",
		"slot": "weapon",
		"display_name": "Iron Spear",
		"value": 1,
		"description": "A bigger spear",
		"stats": {"add": {"attack": 2}, "mul": {"attack_speed": 1.0}}
	},
	"leather_chestplate": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Images/water.png"),
		"card_type": "equipment",
		"slot": "chestplate",
		"display_name": "Leather Chestplate",
		"value": 1,
		"description": "A poorly crafted leather chestplate.",
		"stats": {"add": {"health": 3}}
	},
	"aquifer": {
		"card": preload("res://Images/location_card.png"),
		"sprite": preload("res://Images/plains.png"),
		"card_type": "location",
		"display_name": "Aquifer",
		"value": 10,
	},
	"plains": {
		"card": preload("res://Images/location_card.png"),
		"sprite": preload("res://Images/plains.png"),
		"card_type": "location",
		"display_name": "Plains",
		"value": 10,
	},
	"forest": {
		"card": preload("res://Images/location_card.png"),
		"sprite": preload("res://Images/forest.png"),
		"card_type": "location",
		"display_name": "Forest",
		"value": 10,
	},
	"mountain": {
		"card": preload("res://Images/location_card.png"),
		"sprite": preload("res://Images/mountain.png"),
		"card_type": "location",
		"display_name": "Mountain",
		"value": 10,
	},
	"cave": {
		"card": preload("res://Images/location_card.png"),
		"sprite": preload("res://Images/mountain.png"),
		"card_type": "location",
		"display_name": "Cave",
		"value": 10,
	},
}
