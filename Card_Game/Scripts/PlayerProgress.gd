extends Node

var card_acquired := {}  # subtype -> total acquired
var recipes_completed := {}     # recipe_name -> times completed
var achievements_unlocked := {} # achievement_id -> bool

func increment_card_count(subtype: String) -> void:
	card_acquired[subtype] = card_acquired.get(subtype, 0) + 1

func increment_recipe(recipe_name: String) -> void:
	recipes_completed[recipe_name] = recipes_completed.get(recipe_name, 0) + 1

func unlock_achievement(achievement_id: String) -> void:
	if not achievements_unlocked.has(achievement_id):
		achievements_unlocked[achievement_id] = true
		print("Achievement unlocked:", achievement_id)

# ==============================
# Debug: print all progress
# ==============================
func print_progress() -> void:
	print("=== Player Progress ===")
	print("Cards acquired:")
	for subtype in card_acquired.keys():
		print(" - %s: %d" % [subtype, card_acquired[subtype]])
	print("Recipes completed:")
	for recipe_name in recipes_completed.keys():
		print(" - %s: %d" % [recipe_name, recipes_completed[recipe_name]])
	print("Achievements unlocked:")
	for achievement_id in achievements_unlocked.keys():
		print(" - %s" % achievement_id)
	print("======================")

# ==============================
# Debug keypress
# ==============================
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		print_progress()
