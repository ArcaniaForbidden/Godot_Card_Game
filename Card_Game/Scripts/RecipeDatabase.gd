extends Node
class_name RecipeDatabase

static var recipes = {
	"Chop Tree": {
		"inputs": [
			{"subtype": "tree", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "wood"},
			{"subtype": "wood"}
		],
		"work_time": 15.0
	},
	"Mine Rock": {
		"inputs": [
			{"subtype": "rock", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "stone"},
			{"subtype": "stone"}
		],
		"work_time": 15.0
	},
	"Mine Iron Deposit": {
		"inputs": [
			{"subtype": "iron_deposit", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "iron_ore"},
			{"subtype": "iron_ore"}
		],
		"work_time": 15.0
	},
	"Mine Copper Deposit": {
		"inputs": [
			{"subtype": "copper_deposit", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "copper_ore"},
			{"subtype": "copper_ore"}
		],
		"work_time": 15.0
	},
	"Mine Gold Deposit": {
		"inputs": [
			{"subtype": "gold_deposit", "consume": true},
			{"subtype": "peasant", "consume": false}
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
			{"weight": 5, "outputs": [{"subtype": "plains"}]},
			{"weight": 5, "outputs": [{"subtype": "forest"}], "requirement": {"recipe_name": "Search Plains", "amount": 20}},
			{"weight": 5, "outputs": [{"subtype": "water_deposit"}]},
			#{"weight": 10, "outputs": [{"subtype": "soil"}]},
			{"weight": 15, "outputs": [{"subtype": "tree"}]},
			{"weight": 15, "outputs": [{"subtype": "rock"}]},
			#{"weight": 5, "outputs": [{"subtype": "cow"}]},
			#{"weight": 5, "outputs": [{"subtype": "horse"}]},
		],
		"work_time": 15.0
	},
	"Search Forest": {
		"inputs": [
			{"subtype": "forest", "consume": false}, # environment card
			{"subtype": "peasant", "consume": false} # unit on top
		],
		"loot_table": [
			{"weight": 50, "outputs": [{"subtype": "tree"}]},
			{"weight": 5, "outputs": [{"subtype": "forest"}]},
			{"weight": 5, "outputs": [{"subtype": "mountain"}], "requirement": {"recipe_name": "Search Forest", "amount": 20}},
			#{"weight": 5, "outputs": [{"subtype": "wolf"}], "requirement": {"recipe_name": "Search Forest", "amount": 10}},
		],
		"work_time": 15.0
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
		"work_time": 10.0
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
			{"subtype": "plank", "consume": true},
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
			{"subtype": "plank", "consume": true},
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
			{"subtype": "plank", "consume": true},
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
			{"subtype": "forest", "consume": false},      # location
			{"subtype": "iron_mine", "consume": false}, # building
			{"subtype": "peasant", "consume": false}      # unit
		],
		"loot_table": [
			{"weight": 45, "outputs": [{"subtype": "iron_ore"}]},
			#{"weight": 5, "outputs": [{"subtype": "gem"}]},
		],
		"work_time": 30.0
	},
	"Make Plank": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true}
		],
		"outputs": [
			{"subtype": "plank"}
		],
		"work_time": 5.0
	},
	"Make Brick": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "stone", "consume": true},
			{"subtype": "stone", "consume": true},
			{"subtype": "stone", "consume": true}
		],
		"outputs": [
			{"subtype": "brick"}
		],
		"work_time": 5.0
	},
}
