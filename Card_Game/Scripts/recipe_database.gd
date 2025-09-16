extends Node
class_name RecipeDatabase

# Recipe database structured with names as keys for readability
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
		"work_time": 10.0
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
		"work_time": 10.0
	},
	"Search Forest": {
		"inputs": [
			{"subtype": "forest", "consume": false},
			{"subtype": "peasant", "consume": false}
		],
		"loot_table": [
			{"weight": 10, "outputs": [{"subtype": "tree"}]},
			{"weight": 50, "outputs": [{"subtype": "wood"}]}
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
			{"subtype": "lumber_camp", "consume": false},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "wood"}
		],
		"work_time": 5.0
	},
	"Use Quarry": {
		"inputs": [
			{"subtype": "quarry", "consume": false},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "stone"}
		],
		"work_time": 5.0
	},
	"Craft Wooden Spear": {
		"inputs": [
			{"subtype": "wood", "consume": true},
			{"subtype": "wood", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "wooden_spear"}
		],
		"work_time": 10.0
	}
}
