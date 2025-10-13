extends Node
class_name CardDatabase

static var card_database = {
	"copper_coin": {
		"card": preload("res://Images/currency_card.png"),
		"sprite": preload("res://Images/copper_coin.png"),
		"card_type": "currency",
		"display_name": "Copper Coin",
		"value": 1,
		"description": "A dull copper coin."
	},
	"silver_coin": {
		"card": preload("res://Images/currency_card.png"),
		"sprite": preload("res://Images/silver_coin.png"),
		"card_type": "currency",
		"display_name": "Silver Coin",
		"value": 10,
		"rarity": "silver",
		"description": "A silver coin. Worth 10 copper coins."
	},
	"gold_coin": {
		"card": preload("res://Images/currency_card.png"),
		"sprite": preload("res://Images/gold_coin.png"),
		"card_type": "currency",
		"display_name": "Gold Coin",
		"value": 100,
		"rarity": "gold",
		"description": "A shiny gold coin. Worth 10 silver coins."
	},
	"plains_card_pack": {
		"card": preload("res://Images/plains_card_pack.png"),
		"sprite": preload("res://Images/blank.png"),
		"card_type": "card_pack",
		"display_name": "",
		"rarity": "silver",
		"description": "The plains card pack. The starting location pack.",
		"loot_table": [
			{"subtype": "plains", "weight": 10},
			{"subtype": "plant_fiber", "weight": 45},
			{"subtype": "soil", "weight": 35},
			#{"subtype": "horse", "weight": 5},
			#{"subtype": "cow", "weight": 5},
		]
	},
	"forest_card_pack": {
		"card": preload("res://Images/forest_card_pack.png"),
		"sprite": preload("res://Images/blank.png"),
		"card_type": "card_pack",
		"display_name": "",
		"rarity": "silver",
		"description": "The forest card pack.",
		"loot_table": [
			{"subtype": "forest", "weight": 10},
			{"subtype": "tree", "weight": 20},
			{"subtype": "wood", "weight": 70},
		]
	},
	"mountain_card_pack": {
		"card": preload("res://Images/mountain_card_pack.png"),
		"sprite": preload("res://Images/blank.png"),
		"card_type": "card_pack",
		"display_name": "",
		"rarity": "silver",
		"description": "The mountain card pack.",
		"loot_table": [
			{"subtype": "mountain", "weight": 10},
			{"subtype": "rock", "weight": 15},
			{"subtype": "iron_deposit", "weight": 4},
			{"subtype": "copper_deposit", "weight": 4},
			{"subtype": "gold_deposit", "weight": 2},
			{"subtype": "stone", "weight": 65},
		]
	},
	"tree": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/tree.png"),
		"card_type": "resource",
		"display_name": "Tree",
		"value": 0,
	},
	"rock": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/rock.png"),
		"card_type": "resource",
		"display_name": "Rock",
		"value": 0,
	},
	"iron_deposit": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/iron_deposit.png"),
		"card_type": "resource",
		"display_name": "Iron Deposit",
		"value": 0,
	},
	"copper_deposit": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/copper_deposit.png"),
		"card_type": "resource",
		"display_name": "Copper Deposit",
		"value": 0,
	},
	"gold_deposit": {
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/gold_deposit.png"),
		"card_type": "resource",
		"display_name": "Gold Deposit",
		"value": 0,
	},
	"soil": { 
		"card": preload("res://Images/resource_card.png"),
		"sprite": preload("res://Images/soil.png"),
		"card_type": "material",
		"display_name": "Soil",
		"value": 0,
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
		"value": 0,
	},
	"plant_fiber": {
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/plant_fiber.png"),
		"card_type": "material",
		"display_name": "Plant Fiber",
		"value": 0,
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
		"value": 4,
	},
	"brick": { 
		"card": preload("res://Images/material_card.png"),
		"sprite": preload("res://Images/brick.png"),
		"card_type": "material",
		"display_name": "Brick",
		"value": 4,
	},
	"house": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/house.png"),
		"card_type": "building",
		"display_name": "House",
		"value": 5,
		"stats": {"health": 25}
	},
	"makeshift_laboratory": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/well.png"),
		"card_type": "building",
		"display_name": "Makeshift Laboratory",
		"value": 5,
		"description": "A simple laboratory.",
		"stats": {"health": 25}
	},
	"well": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/well.png"),
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
		"sprite": preload("res://Images/iron_mine.png"),
		"card_type": "building",
		"display_name": "Iron Mine",
		"value": 5,
		"stats": {"health": 25}
	},
	"copper_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/copper_mine.png"),
		"card_type": "building",
		"display_name": "Copper Mine",
		"value": 5,
		"stats": {"health": 25}
	},
	"gold_mine": {
		"card": preload("res://Images/building_card.png"),
		"sprite": preload("res://Images/gold_mine.png"),
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
		"description": "A large body of water underground.",
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
		"sprite": preload("res://Images/cave.png"),
		"card_type": "location",
		"display_name": "Cave",
		"value": 10,
	},
	"peasant": {
		"card": preload("res://Images/unit_card.png"),
		"sprite": preload("res://Animations/peasant.tres"),
		"animated": true,
		"card_type": "unit",
		"attack_type": "ranged",
		"display_name": "Peasant",
		"stats": {"health": 10, "attack": 0, "armor": 0, "attack_speed": 0.8},
	},
	"wolf": {
		"card": preload("res://Images/enemy_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "enemy",
		"display_name": "Wolf",
		"stats": {"health": 4, "attack": 1, "armor": 0, "attack_speed": 1.2},
		"loot_table": [
			{ "subtype": "wood", "chance": 0.8 },
			{ "subtype": "tree", "chance": 0.7 }
		]
	},
	"horse": {
		"card": preload("res://Images/neutral_card.png"),
		"sprite": preload("res://Images/horse.png"),
		"card_type": "neutral",
		"display_name": "Wolf",
		"stats": {"health": 5, "attack": 1, "armor": 0, "attack_speed": 1.0},
		"loot_table": [
			{ "subtype": "wood", "chance": 0.8 },
			{ "subtype": "tree", "chance": 0.7 }
		]
	},
	"cow": {
		"card": preload("res://Images/neutral_card.png"),
		"sprite": preload("res://Images/wolf.png"),
		"card_type": "neutral",
		"display_name": "Wolf",
		"stats": {"health": 4, "attack": 1, "armor": 0, "attack_speed": 0.8},
		"loot_table": [
			{ "subtype": "wood", "chance": 0.8 },
			{ "subtype": "tree", "chance": 0.7 }
		]
	},
}
