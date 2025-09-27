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
	"Search Forest": {
		"inputs": [
			{"subtype": "forest", "consume": false}, # environment card
			{"subtype": "peasant", "consume": false} # unit on top
		],
		"loot_table": [
			{"weight": 10, "outputs": [{"subtype": "tree"}]},
			{"weight": 50, "outputs": [{"subtype": "wood"}]}
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
			{"weight": 2, "outputs": [{"subtype": "brick"}], "requirement": {"recipe_name": "Search Plains", "amount": 5}},
			{"weight": 10, "outputs": [{"subtype": "tree"}]},
			{"weight": 10, "outputs": [{"subtype": "rock"}]},
			{"weight": 30, "outputs": [{"subtype": "wood"}]},
			{"weight": 30, "outputs": [{"subtype": "stone"}]}
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
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "stone", "consume": true},
			{"subtype": "stone", "consume": true},
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
	"Use Lumber Camp": {
		"inputs": [
			{"subtype": "lumber_camp", "consume": false}, # building
			{"subtype": "peasant", "consume": false}      # unit
		],
		"outputs": [
			{"subtype": "wood"}
		],
		"work_time": 7.5
	},
	"Use Lumber Camp on Forest": {
		"inputs": [
			{"subtype": "forest", "consume": false},      # location
			{"subtype": "lumber_camp", "consume": false}, # building
			{"subtype": "peasant", "consume": false}      # unit
		],
		"outputs": [
			{"subtype": "wood"}
		],
		"work_time": 5.0
	},
	"Use Quarry": {
		"inputs": [
			{"subtype": "quarry", "consume": false}, # building
			{"subtype": "peasant", "consume": false} # unit
		],
		"outputs": [
			{"subtype": "stone"}
		],
		"work_time": 2.0
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
