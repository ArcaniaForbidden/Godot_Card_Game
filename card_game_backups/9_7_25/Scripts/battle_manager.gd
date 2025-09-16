extends Node2D

# Signals
signal battle_started(zone_id)
signal battle_ended(zone_id)

# Constants
const BATTLE_ZONE_SIZE := Vector2(300, 200)
const ATTACK_CHECK_INTERVAL := 0.1  # seconds per process step

# Battle data
var battle_zones: Array = []  # each element: {"units": [], "enemies": [], "position": Vector2, "attack_timers": {}}
var battle_zone_scene = preload("res://Scenes/battle_zone.tscn") # optional visual

func _ready():
	# Connect to card manager signals
	var card_manager = get_node("/root/CardManager")  # adjust path
	card_manager.connect("card_entered_battle", self, "_on_card_entered_battle")

func _process(delta):
	for zone in battle_zones:
		process_battle_zone(zone, delta)

# ------------------------------
# CARD ENTERS BATTLE
# ------------------------------
func _on_card_entered_battle(card: Node2D):
	if card.in_battle:
		return
	var zone = find_existing_zone_for(card)
	if not zone:
		zone = create_new_battle_zone(card)
	add_card_to_zone(card, zone)

# ------------------------------
# BATTLE ZONE MANAGEMENT
# ------------------------------
func find_existing_zone_for(card: Node2D) -> Dictionary:
	for zone in battle_zones:
		var rect = Rect2(zone["position"] - BATTLE_ZONE_SIZE/2, BATTLE_ZONE_SIZE)
		if rect.has_point(card.position):
			return zone
	return null

func create_new_battle_zone(card: Node2D) -> Dictionary:
	var zone = {
		"units": [],
		"enemies": [],
		"position": card.position,
		"attack_timers": {}
	}
	# Optional visual
	var zone_instance = battle_zone_scene.instantiate()
	add_child(zone_instance)
	zone_instance.position = zone["position"]
	zone["zone_instance"] = zone_instance
	battle_zones.append(zone)
	emit_signal("battle_started", zone.get("id", battle_zones.size() - 1))
	return zone

func add_card_to_zone(card: Node2D, zone: Dictionary) -> void:
	card.in_battle = true
	if card.card_type == "enemy":
		zone["enemies"].append(card)
	else:
		zone["units"].append(card)
	zone["attack_timers"][card] = 0.0

# ------------------------------
# BATTLE PROCESSING
# ------------------------------
func process_battle_zone(zone: Dictionary, delta: float) -> void:
	var all_cards = zone["units"] + zone["enemies"]
	# Update attack timers
	for card in all_cards:
		zone["attack_timers"][card] -= delta

	# Process attacks
	for card in all_cards:
		if zone["attack_timers"][card] <= 0:
			attack_random_target(card, zone)
			zone["attack_timers"][card] = card.attack_speed  # attack cooldown

	# Remove dead cards
	for card in all_cards.duplicate():
		if card.health <= 0:
			remove_card_from_zone(card, zone)

	# Check for battle end
	if zone["units"].size() == 0 or zone["enemies"].size() == 0:
		end_battle(zone)

func attack_random_target(attacker: Node2D, zone: Dictionary) -> void:
	var targets = zone["units"] if attacker.card_type == "enemy" else zone["enemies"]
	if targets.size() == 0:
		return
	var target = targets[randi() % targets.size()]
	target.health -= attacker.attack
	# Update health label
	if target.has_node("HealthLabel"):
		target.get_node("HealthLabel").text = str(target.health)

func remove_card_from_zone(card: Node2D, zone: Dictionary) -> void:
	if card in zone["units"]:
		zone["units"].erase(card)
	if card in zone["enemies"]:
		zone["enemies"].erase(card)
	zone["attack_timers"].erase(card)
	card.in_battle = false

func end_battle(zone: Dictionary) -> void:
	for card in zone["units"] + zone["enemies"]:
		card.in_battle = false
	if zone.has("zone_instance"):
		zone["zone_instance"].queue_free()
	battle_zones.erase(zone)
	emit_signal("battle_ended", zone.get("id", -1))
