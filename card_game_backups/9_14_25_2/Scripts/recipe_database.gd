extends Node
class_name RecipeDatabase

# Each recipe:
# name: String
# inputs: Array of dictionaries
#   - subtype: String
#   - consume: bool  # whether the card is consumed or not
# outputs: Array of dictionaries
#   - subtype: String
#   - count: int
# work_time: float

static var recipes = [
	{
		"name": "Chop Tree",
		"inputs": [
			{"subtype": "tree", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "wood"},
			{"subtype": "wood"}
		],
		"work_time": 5.0
	},
	{
		"name": "Mine Rock",
		"inputs": [
			{"subtype": "rock", "consume": true},
			{"subtype": "peasant", "consume": false}
		],
		"outputs": [
			{"subtype": "stone"},
			{"subtype": "stone"}
		],
		"work_time": 5.0
	},
		{
		"name": "Search Forest",
		"inputs": [
			{"subtype": "forest", "consume": false},
			{"subtype": "peasant", "consume": false}
		],
		"loot_table": [
			{ "weight": 10, "outputs": [ { "subtype": "tree"} ] },
			{ "weight": 50, "outputs": [ { "subtype": "wood"} ] }
		],
		"work_time": 10.0
	},
	{
		"name": "Build House",
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
	{
		"name": "Build Lumber Camp",
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
]
