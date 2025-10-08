extends Node

var card_acquired := {}  		# subtype -> total acquired
var card_pack_opened := {}		# pack_subtype -> times opened
var recipes_completed := {}     # recipe_name -> times completed
var achievements_unlocked := {} # achievement_id -> bool

func increment_card_count(subtype: String) -> void:
	card_acquired[subtype] = card_acquired.get(subtype, 0) + 1

func increment_card_pack_opened(pack_subtype: String) -> void:
	card_pack_opened[pack_subtype] = card_pack_opened.get(pack_subtype, 0) + 1
	print("Card pack opened:", pack_subtype, "Total opened:", card_pack_opened[pack_subtype])

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
	print("Card packs opened:")
	for pack_subtype in card_pack_opened.keys():
		print(" - %s: %d" % [pack_subtype, card_pack_opened[pack_subtype]])
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
