extends Node

var card_manager: CardManager = null
var card_database = preload("res://Scripts/CardDatabase.gd").card_database
var days_since_last_raid: int = 0
var active_raid_enemies := []

@export var VALUE_SCALE := 0.01           # 1 enemy strength per 100 value
@export var DAY_SCALE := 0.5              # 0.5 strength per day
@export var UNIT_SCALE := 1.0             # 1 strength per unit
@export var BUILDING_SCALE := 0.2         # 0.2 strength per building
@export var BASE_RAID_STRENGTH := 3       # Minimum raid power

func _ready():
	card_manager = get_node_or_null("/root/Main/CardManager")
	if not card_manager:
		push_error("RaidManager could not find CardManager!")
	if TimeManager:
		TimeManager.connect("night_started", Callable(self, "_on_night_started"))
	else:
		push_error("RaidManager could not find TimeManager!")

func get_total_value() -> int:
	if not card_manager:
		return 0
	var total_value := 0
	for stack in card_manager.all_stacks:
		for card in stack:
			if is_instance_valid(card) and card.value != null:
				total_value += card.value
	return total_value

func get_unit_count() -> int:
	if not card_manager:
		return 0
	var unit_count := 0
	for stack in card_manager.all_stacks:
		for card in stack:
			if is_instance_valid(card) and card.card_type == "unit":
				unit_count += 1
	return unit_count

func get_building_count() -> int:
	if not card_manager:
		return 0
	var building_count := 0
	for stack in card_manager.all_stacks:
		for card in stack:
			if is_instance_valid(card) and card.card_type == "building":
				building_count += 1
	return building_count

func get_raid_strength() -> int:
	if not TimeManager:
		return BASE_RAID_STRENGTH
	var total_value := get_total_value()
	var unit_count := get_unit_count()
	var building_count := get_building_count()
	var current_day := TimeManager.get_day_count()
	var raid_strength := int(
		(total_value * VALUE_SCALE) +
		(current_day * DAY_SCALE) +
		(unit_count * UNIT_SCALE) +
		(building_count * BUILDING_SCALE)
	)
	return max(raid_strength, BASE_RAID_STRENGTH)

func spawn_raid() -> void:
	var raid_strength := get_raid_strength()
	print("⚔️ Spawning raid with strength:", raid_strength)
	var remaining_strength := raid_strength
	var enemy_subtypes := []
	for subtype in card_database.keys():
		var card_data = card_database[subtype]
		if card_data.has("card_type") and card_data.card_type == "enemy":
			enemy_subtypes.append(subtype)
	if enemy_subtypes.is_empty():
		print("⚠️ No enemy cards found in CardDatabase!")
		return
	while remaining_strength > 0:
		var subtype = enemy_subtypes[randi() % enemy_subtypes.size()]
		var enemy_data = card_database[subtype]
		var raid_value = enemy_data.get("raid_value", 1)
		var group_range = enemy_data.get("raid_group_range", Vector2(1, 3))
		var group_size = randi_range(int(group_range.x), int(group_range.y))
		var group_cost = raid_value * group_size
		if group_cost > remaining_strength:
			group_size = int(remaining_strength / raid_value)
			if group_size <= 0:
				break
		remaining_strength -= raid_value * group_size
		var spawn_pos = get_random_edge_position()
		var scatter_radius := 100
		for i in range(group_size):
			if card_manager:
				var offset = Vector2(randf_range(-scatter_radius, scatter_radius), randf_range(-scatter_radius, scatter_radius))
				var spawned_enemy = card_manager.spawn_card(subtype, spawn_pos + offset)
				if spawned_enemy:
					spawned_enemy.set("is_raid_enemy", true)
					active_raid_enemies.append(spawned_enemy)
					spawned_enemy.connect("died", Callable(self, "_on_raid_enemy_died"))
		print("Spawned %d %s enemies at %s" % [group_size, subtype, spawn_pos])

func get_random_edge_position() -> Vector2:
	var map_manager = get_node_or_null("/root/Main/MapManager") as MapManager
	if not map_manager or not map_manager.map_rect:
		return Vector2.ZERO
	var rect = map_manager.map_rect
	var edge = randi() % 3
	match edge:
		0: return Vector2(randf() * rect.size.x + rect.position.x, rect.position.y + rect.size.y) # bottom
		1: return Vector2(rect.position.x, randf() * rect.size.y + rect.position.y)               # left
		2: return Vector2(rect.position.x + rect.size.x, randf() * rect.size.y + rect.position.y) # right
	return rect.position

func roll_for_raid() -> void:
	var chance: float = clamp(days_since_last_raid * 0.25, 0.0, 1.0)
	if randf() < chance:
		spawn_raid()
		if SoundManager:
			SoundManager.play("raid_start", 0.0)
		print("Spawning raid")
	else:
		print("No raid tonight")
		show_next_day_button()

func _on_raid_enemy_died(card):
	if card in active_raid_enemies:
		active_raid_enemies.erase(card)
		print("Raid enemy killed: %s, remaining: %d" % [card.name, active_raid_enemies.size()])
		if active_raid_enemies.is_empty():
			print("✅ All raid enemies defeated!")
			days_since_last_raid = 0
			show_next_day_button()

func show_next_day_button():
	if UIManager.next_day_button:
		UIManager.next_day_button.disabled = false
		UIManager.next_day_button.show()
		UIManager.next_day_button.modulate.a = 0.0
		repair_buildings()
	if not UIManager.next_day_button: 
		return
	var tween := create_tween()
	tween.tween_property(UIManager.next_day_button, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func repair_buildings():
	var repaired_buildings := false
	for stack in card_manager.all_stacks:
		for building_card in stack:
			if not is_instance_valid(building_card):
				continue
			if building_card.card_type == "building":
				if building_card.health < building_card.max_health:
					var full_repair = building_card.max_health - building_card.health
					building_card.heal(full_repair)
					repaired_buildings = true
	if repaired_buildings == true and SoundManager:
		SoundManager.play("repair_building", -4.0)
