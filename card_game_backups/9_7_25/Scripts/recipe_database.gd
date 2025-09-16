extends Node
class_name RecipeDatabase   # Global access by name

# Each recipe defines:
# - ingredients: Array of dictionaries {subtype: String, consumes: bool}
# - products: Array of dictionaries {subtype: String, amount: int}
# - work_time: float (seconds)

static var recipes := [
	{
		"ingredients": [
			{"subtype": "villager", "consumes": false},
			{"subtype": "tree", "consumes": true}
		],
		"products": [
			{"subtype": "wood", "amount": 3}
		],
		"work_time": 5.0
	},
	{
		"ingredients": [
			{"subtype": "villager", "consumes": false},
			{"subtype": "rock", "consumes": true}
		],
		"products": [
			{"subtype": "stone", "amount": 3}
		],
		"work_time": 5.0
	}
]
