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
			{"subtype": "tree", "consume": true},       # consumable input
			{"subtype": "peasant", "consume": false}   # worker
		],
		"outputs": [
			{"subtype": "wood"},
			{"subtype": "wood"}
		],
		"work_time": 8.0
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
		"work_time": 8.0
	}
]
