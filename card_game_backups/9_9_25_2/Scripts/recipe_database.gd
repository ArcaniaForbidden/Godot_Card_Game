extends Node
class_name RecipeDatabase
# Recipes are order-sensitive and adjacency-based.
# Each recipe has:
#   "consumed"  : Array of subtypes required in order
#   "persistent" : Array of cards not consumed
#   "output" : Arroy of cards produced
#   "craft_time" : Time in seconds for the crafting to finish

static var recipes = [
	{
		"consumed": ["wood", "wood"],  # must be top of stack
		"persistent": ["villager"],    # villager must be in stack but not consumed
		"output": ["stone", "stone"],
		"craft_time": 3.0
	},
	{
		"consumed": ["stone", "stone"],
		"persistent": ["villager"],
		"output": ["wood", "wood"],
		"craft_time": 3.0
	}
]
