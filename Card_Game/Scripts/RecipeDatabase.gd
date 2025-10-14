extends Node
class_name RecipeDatabase

static var recipes = {
	"Chop Tree": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "tree", "consume": true}
		],
		"outputs": [
			{"subtype": "wood"},
			{"subtype": "wood"}
		],
		"work_time": 15.0
	},
	"Mine Rock": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "rock", "consume": true}
		],
		"outputs": [
			{"subtype": "stone"},
			{"subtype": "stone"}
		],
		"work_time": 15.0
	},
	"Mine Iron Deposit": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "iron_deposit", "consume": true}
		],
		"outputs": [
			{"subtype": "iron_ore"},
			{"subtype": "iron_ore"}
		],
		"work_time": 15.0
	},
	"Mine Copper Deposit": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "copper_deposit", "consume": true}
		],
		"outputs": [
			{"subtype": "copper_ore"},
			{"subtype": "copper_ore"}
		],
		"work_time": 15.0
	},
	"Mine Gold Deposit": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "gold_deposit", "consume": true}
		],
		"outputs": [
			{"subtype": "gold_ore"},
			{"subtype": "gold_ore"}
		],
		"work_time": 15.0
	},
	"Search Plains": {
		"inputs": [
			{"subtype": "plains", "consume": false}, # environment card
			{"subtype": "peasant", "consume": false} # unit on top
		],
		"loot_table": [
			{"weight": 1, "outputs": [{"subtype": "aquifer"}]},
			{"weight": 5, "outputs": [{"subtype": "soil"}]},
			{"weight": 8, "outputs": [{"subtype": "plant_fiber"}]},
			{"weight": 4, "outputs": [{"subtype": "tree"}]},
			{"weight": 4, "outputs": [{"subtype": "rock"}]},
			#{"weight": 2, "outputs": [{"subtype": "cow"}]},
			{"weight": 2, "outputs": [{"subtype": "horse"}]},
		],
		"work_time": 30.0
	},
	"Search Forest": {
		"inputs": [
			{"subtype": "forest", "consume": false}, # environment card
			{"subtype": "peasant", "consume": false} # unit on top
		],
		"loot_table": [
			{"weight": 10, "outputs": [{"subtype": "plant_fiber"}]},
			{"weight": 45, "outputs": [{"subtype": "tree"}]},
			{"weight": 40, "outputs": [{"subtype": "wood"}]},
			{"weight": 5, "outputs": [{"subtype": "wolf"}], "requirement": {"recipe_name": "Search Forest", "amount": 15}},
		],
		"work_time": 30.0
	},
	"Search Mountain": {
		"inputs": [
			{"subtype": "mountain", "consume": false}, # environment card
			{"subtype": "peasant", "consume": false} # unit on top
		],
		"loot_table": [
			{"weight": 50, "outputs": [{"subtype": "rock"}]},
			{"weight": 35, "outputs": [{"subtype": "stone"}]},
			{"weight": 5, "outputs": [{"subtype": "cave"}]},
			{"weight": 4, "outputs": [{"subtype": "iron_deposit"}], "requirement": {"recipe_name": "Search Mountain", "amount": 30}},
			{"weight": 4, "outputs": [{"subtype": "copper_deposit"}], "requirement": {"recipe_name": "Search Mountain", "amount": 30}},
			{"weight": 2, "outputs": [{"subtype": "gold_deposit"}], "requirement": {"recipe_name": "Search Mountain", "amount": 50}},
		],
		"work_time": 30.0
	},
	"Search Cave": {
		"inputs": [
			{"subtype": "cave", "consume": false}, # environment card
			{"subtype": "peasant", "consume": false} # unit on top
		],
		"loot_table": [
			{"weight": 45, "outputs": [{"subtype": "rock"}]},
			{"weight": 35, "outputs": [{"subtype": "stone"}]},
			{"weight": 8, "outputs": [{"subtype": "iron_deposit"}], "requirement": {"recipe_name": "Search Mountain", "amount": 30}},
			{"weight": 8, "outputs": [{"subtype": "copper_deposit"}], "requirement": {"recipe_name": "Search Mountain", "amount": 30}},
			{"weight": 4, "outputs": [{"subtype": "gold_deposit"}], "requirement": {"recipe_name": "Search Mountain", "amount": 50}},
		],
		"work_time": 30.0
	},
	"Craft Wooden Spear": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true}
		],
		"outputs": [
			{"subtype": "wooden_spear"}
		],
		"work_time": 15.0
	},
	"Craft Leather Helmet": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "leather", "consume": true},
			{"subtype": "leather", "consume": true},
			{"subtype": "plant_fiber", "consume": true}
		],
		"outputs": [
			{"subtype": "leather_helmet"}
		],
		"work_time": 15.0
	},
	"Craft Leather Chestplate": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "leather", "consume": true},
			{"subtype": "leather", "consume": true},
			{"subtype": "leather", "consume": true},
			{"subtype": "leather", "consume": true},
			{"subtype": "plant_fiber", "consume": true}
		],
		"outputs": [
			{"subtype": "leather_chestplate"}
		],
		"work_time": 15.0
	},
	"Craft Leather Leggings": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "leather", "consume": true},
			{"subtype": "leather", "consume": true},
			{"subtype": "leather", "consume": true},
			{"subtype": "plant_fiber", "consume": true}
		],
		"outputs": [
			{"subtype": "leather_leggings"}
		],
		"work_time": 15.0
	},
	"Craft Leather Boots": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "leather", "consume": true},
			{"subtype": "plant_fiber", "consume": true}
		],
		"outputs": [
			{"subtype": "leather_boots"}
		],
		"work_time": 15.0
	},
	"Craft Plank": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true}
		],
		"outputs": [
			{"subtype": "plank"}
		],
		"work_time": 10.0
	},
	"Craft Brick": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "stone", "consume": true},
			{"subtype": "stone", "consume": true},
			{"subtype": "stone", "consume": true}
		],
		"outputs": [
			{"subtype": "brick"}
		],
		"work_time": 10.0
	},
	"Craft Rope": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "plant_fiber", "consume": true},
			{"subtype": "plant_fiber", "consume": true},
			{"subtype": "plant_fiber", "consume": true}
		],
		"outputs": [
			{"subtype": "rope"}
		],
		"work_time": 10.0
	},
	"Cook Raw Meat": {
		"inputs": [
			{"subtype": "campfire", "consume": false},
			{"subtype": "raw_meat", "consume": true}
		],
		"outputs": [
			{"subtype": "cooked_meat"}
		],
		"work_time": 10.0
	},
	"Build Campfire": {
		"inputs": [
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "plant_fiber", "consume": true},
			{"subtype": "plant_fiber", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "campfire"}
		],
		"work_time": 15.0
	},
	"Build House": {
		"inputs": [
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "house"}
		],
		"work_time": 15.0
	},
	"Build Smeltery": {
		"inputs": [
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "smeltery"}
		],
		"work_time": 15.0
	},
	"Build Forge": {
		"inputs": [
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "forge"}
		],
		"work_time": 15.0
	},
	"Build Barracks": {
		"inputs": [
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "barracks"}
		],
		"work_time": 15.0
	},
	"Build Well": {
		"inputs": [
			{"subtype": "brick", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "rope", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "well"}
		],
		"work_time": 15.0
	},
	"Build Wishing Well": {
		"inputs": [
			{"subtype": "well", "consume": true},
			{"subtype": "iron_ingot", "consume": true},
			{"subtype": "copper_ingot", "consume": true},
			{"subtype": "gold_ingot", "consume": true},
			#{"subtype": "gem", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "wishing_well"}
		],
		"work_time": 15.0
	},
	"Build Lumber Camp": {
		"inputs": [
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "tree", "consume": true},
			{"subtype": "tree", "consume": true},
			{"subtype": "tree", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "lumber_camp"}
		],
		"work_time": 15.0
	},
	"Build Quarry": {
		"inputs": [
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "rock", "consume": true},
			{"subtype": "rock", "consume": true},
			{"subtype": "rock", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "quarry"}
		],
		"work_time": 15.0
	},
	"Build Iron Mine": {
		"inputs": [
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			#{"subtype": "iron_bar", "consume": true},
			{"subtype": "iron_deposit", "consume": true},
			{"subtype": "iron_deposit", "consume": true},
			{"subtype": "iron_deposit", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "iron_mine"}
		],
		"work_time": 15.0
	},
	"Build Copper Mine": {
		"inputs": [
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			#{"subtype": "iron_bar", "consume": true},
			{"subtype": "copper_deposit", "consume": true},
			{"subtype": "copper_deposit", "consume": true},
			{"subtype": "copper_deposit", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "copper_mine"}
		],
		"work_time": 15.0
	},
	"Build Gold Mine": {
		"inputs": [
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			#{"subtype": "iron_bar", "consume": true},
			{"subtype": "gold_deposit", "consume": true},
			{"subtype": "gold_deposit", "consume": true},
			{"subtype": "gold_deposit", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "gold_mine"}
		],
		"work_time": 15.0
	},
	"Use Well": {
		"inputs": [
			{"subtype": "aquifer", "consume": false},      # location
			{"subtype": "well", "consume": false}, # building
			{"subtype": "peasant", "consume": false}      # unit
		],
		"loot_table": [
			{"weight": 1, "outputs": [{"subtype": "water"}]},
		],
		"work_time": 15.0
	},
	"Use Lumber Camp": {
		"inputs": [
			{"subtype": "forest", "consume": false},      # location
			{"subtype": "lumber_camp", "consume": false}, # building
			{"subtype": "peasant", "consume": false}      # unit
		],
		"loot_table": [
			{"weight": 45, "outputs": [{"subtype": "wood"}]},
			#{"weight": 5, "outputs": [{"subtype": "resin"}]},
		],
		"work_time": 15.0
	},
	"Use Quarry": {
		"inputs": [
			{"subtype": "mountain", "consume": false},
			{"subtype": "quarry", "consume": false}, # building
			{"subtype": "peasant", "consume": false} # unit
		],
		"outputs": [
			{"subtype": "stone"}
		],
		"work_time": 15.0
	},
	"Use Iron Mine": {
		"inputs": [
			{"subtype": "cave", "consume": false},      # location
			{"subtype": "iron_mine", "consume": false}, # building
			{"subtype": "peasant", "consume": false}      # unit
		],
		"loot_table": [
			{"weight": 45, "outputs": [{"subtype": "iron_ore"}]},
			#{"weight": 5, "outputs": [{"subtype": "gem"}]},
		],
		"work_time": 30.0
	},
	"Use Copper Mine": {
		"inputs": [
			{"subtype": "cave", "consume": false},
			{"subtype": "copper_mine", "consume": false}, # building
			{"subtype": "peasant", "consume": false} # unit
		],
		"loot_table": [
			{"weight": 45, "outputs": [{"subtype": "copper_ore"}]},
			#{"weight": 5, "outputs": [{"subtype": "gem"}]},
		],
		"work_time": 15.0
	},
	"Use Gold Mine": {
		"inputs": [
			{"subtype": "cave", "consume": false},
			{"subtype": "gold_mine", "consume": false}, # building
			{"subtype": "peasant", "consume": false} # unit
		],
		"loot_table": [
			{"weight": 45, "outputs": [{"subtype": "gold_ore"}]},
			#{"weight": 5, "outputs": [{"subtype": "gem"}]},
		],
		"work_time": 15.0
	},
	"Use Smeltery for Iron Ingot": {
		"inputs": [
			{"subtype": "smeltery", "consume": false},     
			{"subtype": "peasant", "consume": false},
			{"subtype": "iron_ore", "consume": true}, 
		],
		"outputs": [
			{"subtype": "iron_ingot"}
		],
		"work_time": 15.0
	},
	"Use Smeltery for Copper Ingot": {
		"inputs": [
			{"subtype": "smeltery", "consume": false},     
			{"subtype": "peasant", "consume": false},
			{"subtype": "copper_ore", "consume": true}, 
		],
		"outputs": [
			{"subtype": "copper_ingot"}
		],
		"work_time": 15.0
	},
	"Use Smeltery for Gold Ingot": {
		"inputs": [
			{"subtype": "smeltery", "consume": false},     
			{"subtype": "peasant", "consume": false},
			{"subtype": "gold_ore", "consume": true}, 
		],
		"outputs": [
			{"subtype": "gold_ingot"}
		],
		"work_time": 15.0
	},
}
