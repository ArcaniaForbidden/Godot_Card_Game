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
		"work_time": 2.0
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
		"work_time": 2.0
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
		"work_time": 10.0
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
			{"subtype": "peasant", "consume": false},
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "stone", "consume": true},
			{"subtype": "stone", "consume": true},
		],
		"outputs": [
			{"subtype": "house"}
		],
		"work_time": 15.0
	},
	"Build Lumber Camp": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "brick", "consume": true},
			{"subtype": "tree", "consume": true},
			{"subtype": "tree", "consume": true},
			{"subtype": "tree", "consume": true},
		],
		"outputs": [
			{"subtype": "lumber_camp"}
		],
		"work_time": 15.0
	},
	"Build Quarry": {
		"inputs": [
			{"subtype": "peasant", "consume": false},
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "plank", "consume": true},
			{"subtype": "rock", "consume": true},
			{"subtype": "rock", "consume": true},
			{"subtype": "rock", "consume": true}
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
		"work_time": 10.0
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
	}
}
