extends Node2D

# --- Constants ---
const SIDE_PADDING := 100          # distance from center line for each side
const LINE_SPACING := 150          # vertical spacing between cards in the line
const ATTACK_TWEEN_TIME := 0.1

# --- Member Variables ---
var card_manager
var active_battles: Array = []    # List of BattleZone instances

# BattleZone data structure
class BattleZone:
	var units: Array = []          # unit cards
	var enemies: Array = []        # enemy cards
	var rect: Rect2 = Rect2()      # battle zone area
	var visual: ColorRect = null   # optional visible rectangle
	var center_position: Vector2 = Vector2.ZERO  # central point of the battle
	var attack_timers: Dictionary = {}  # tracks attack timers per card
	var healing_sources = []  # Array of dictionaries

func _ready() -> void:
	card_manager = get_parent().get_node("CardManager")

func _process(delta: float) -> void:
	update_battle_detection()
	update_battle_zones()
	if not active_battles.is_empty():
		process_battle_combat(delta)

# =======================
# BATTLE DETECTION
# =======================
func update_battle_detection() -> void:
	for stack in card_manager.all_stacks.duplicate():
		var unit_cards: Array = []
		var non_unit_cards: Array = []
		for card in stack:
			if card.card_type == "unit":
				unit_cards.append(card)
			else:
				non_unit_cards.append(card)
		if unit_cards.size() == 0:
			continue
		var overlaps = false
		for unit_card in unit_cards:
			for enemy_stack in card_manager.all_stacks:
				if enemy_stack == stack:
					continue
				var enemy_card = enemy_stack[-1]
				if enemy_card.card_type != "enemy":
					continue
				if card_manager.get_card_global_rect(unit_card).intersects(card_manager.get_card_global_rect(enemy_card)):
					overlaps = true
					break
			if overlaps:
				break
			for battle in active_battles:
				if card_manager.get_card_global_rect(unit_card).intersects(battle.rect):
					overlaps = true
					break
			if overlaps:
				break
		if overlaps:
			start_battle(unit_cards)
			if card_manager.dragged_substack.size() > 0:
				for c in card_manager.dragged_substack:
					if c in unit_cards:
						card_manager.finish_drag()
						break
			stack.clear()
			for c in non_unit_cards:
				stack.append(c)
			if stack.size() == 0:
				card_manager.all_stacks.erase(stack)
			for unit_card in unit_cards:
				var existing_stack = card_manager.find_stack(unit_card)
				if existing_stack.size() == 0:
					card_manager.all_stacks.append([unit_card])

# =======================
# START BATTLE
# =======================
func start_battle(unit_cards: Array) -> void:
	for unit_card in unit_cards:
		if is_card_in_battle(unit_card):
			continue
		var enemy_card: Node2D = null
		for stack in card_manager.all_stacks:
			var top_card = stack[-1]
			if top_card.card_type != "enemy":
				continue
			if card_manager.get_card_global_rect(unit_card).intersects(card_manager.get_card_global_rect(top_card)):
				enemy_card = top_card
				break
		if enemy_card == null:
			continue
		var existing_battle: BattleZone = null
		for battle in active_battles:
			if enemy_card in battle.enemies:
				existing_battle = battle
				break
		if existing_battle:
			existing_battle.units.append(unit_card)
			mark_card_in_battle(unit_card)
			existing_battle.attack_timers[unit_card] = 0.0
		else:
			var battle = BattleZone.new()
			battle.units.append(unit_card)
			battle.enemies.append(enemy_card)
			mark_card_in_battle(unit_card)
			mark_card_in_battle(enemy_card)
			battle.center_position = (unit_card.position + enemy_card.position) * 0.5
			battle.rect = Rect2(battle.center_position, Vector2.ZERO)
			battle.visual = ColorRect.new()
			battle.visual.color = Color(1, 0, 0, 0.3)
			battle.visual.position = battle.rect.position
			battle.visual.size = Vector2(1, 1)
			add_child(battle.visual)
			battle.attack_timers[unit_card] = 0.0
			battle.attack_timers[enemy_card] = 0.0
			active_battles.append(battle)

# =======================
# UPDATE BATTLE ZONES
# =======================
func update_battle_zones() -> void:
	for battle in active_battles.duplicate():
		check_and_add_cards(battle)
		battle.rect = calculate_battle_zone_rect(battle)
		if battle.visual:
			battle.visual.position = battle.rect.position
			battle.visual.size = battle.rect.size
		merge_overlapping_battles()
		lock_cards_in_zone(battle)
		if battle.units.is_empty() or battle.enemies.is_empty():
			end_battle(battle)

func merge_overlapping_battles() -> void:
	for i in range(active_battles.size()):
		for j in range(i + 1, active_battles.size()):
			var battle_a = active_battles[i]
			var battle_b = active_battles[j]
			if battle_a.rect.intersects(battle_b.rect):
				for unit_card in battle_b.units:
					if not unit_card.in_battle:
						mark_card_in_battle(unit_card)
					if unit_card not in battle_a.units:
						battle_a.units.append(unit_card)
				for enemy_card in battle_b.enemies:
					if not enemy_card.in_battle:
						mark_card_in_battle(enemy_card)
					if enemy_card not in battle_a.enemies:
						battle_a.enemies.append(enemy_card)
				battle_a.center_position = (battle_a.center_position + battle_b.center_position) * 0.5
				var all_cards = battle_a.units + battle_a.enemies
				if all_cards.size() > 0:
					var min_x = all_cards[0].position.x
					var max_x = min_x
					var min_y = all_cards[0].position.y
					var max_y = min_y
					for card in all_cards:
						min_x = min(min_x, card.position.x)
						max_x = max(max_x, card.position.x)
						min_y = min(min_y, card.position.y)
						max_y = max(max_y, card.position.y)
					battle_a.rect.position = Vector2(min_x, min_y)
					battle_a.rect.size = Vector2(max_x - min_x, max_y - min_y)
				if battle_b.visual:
					battle_b.visual.queue_free()
				active_battles.erase(battle_b)
				merge_overlapping_battles()
				return

# =======================
# ADD NEW CARDS TO BATTLE
# =======================
func check_and_add_cards(battle: BattleZone) -> void:
	var zone_rect = battle.rect
	for stack in card_manager.all_stacks:
		var unit_cards: Array = []
		var enemy_cards: Array = []
		for card in stack:
			if card.card_type == "unit" and not card.in_battle:
				unit_cards.append(card)
			elif card.card_type == "enemy" and not card.in_battle:
				enemy_cards.append(card)
		if unit_cards.size() == 0 and enemy_cards.size() == 0:
			continue
		for unit_card in unit_cards:
			if card_manager.get_card_global_rect(unit_card).intersects(zone_rect):
				if unit_card not in battle.units:
					battle.units.append(unit_card)
				mark_card_in_battle(unit_card)
				battle.attack_timers[unit_card] = 0.0
		for enemy_card in enemy_cards:
			if card_manager.get_card_global_rect(enemy_card).intersects(zone_rect):
				if enemy_card not in battle.enemies:
					battle.enemies.append(enemy_card)
				mark_card_in_battle(enemy_card)
				battle.attack_timers[enemy_card] = 0.0
	lock_cards_in_zone(battle)

# =======================
# LOCK CARDS IN ZONE
# =======================
func lock_cards_in_zone(battle: BattleZone) -> void:
	var all_cards = battle.units + battle.enemies
	if all_cards.size() == 0:
		return
	var screen_size = get_viewport_rect().size
	var intended_positions: Array = []
	var start_y_units = battle.center_position.y - (battle.units.size() - 1) * LINE_SPACING * 0.5
	for i in range(battle.units.size()):
		intended_positions.append(Vector2(battle.center_position.x - SIDE_PADDING, start_y_units + i * LINE_SPACING))
	var start_y_enemies = battle.center_position.y - (battle.enemies.size() - 1) * LINE_SPACING * 0.5
	for i in range(battle.enemies.size()):
		intended_positions.append(Vector2(battle.center_position.x + SIDE_PADDING, start_y_enemies + i * LINE_SPACING))
	var min_x = intended_positions[0].x
	var max_x = intended_positions[0].x
	var min_y = intended_positions[0].y
	var max_y = intended_positions[0].y
	for pos in intended_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)
	var shift_x = 0.0
	var shift_y = 0.0
	if min_x < 0:
		shift_x = -min_x
	elif max_x > screen_size.x:
		shift_x = screen_size.x - max_x
	if min_y < 0:
		shift_y = -min_y
	elif max_y > screen_size.y:
		shift_y = screen_size.y - max_y
	battle.center_position += Vector2(shift_x, shift_y)
	start_y_units = battle.center_position.y - (battle.units.size() - 1) * LINE_SPACING * 0.5
	for i in range(battle.units.size()):
		var card = battle.units[i]
		card.position = Vector2(battle.center_position.x - SIDE_PADDING, start_y_units + i * LINE_SPACING)
		card.is_being_dragged = true
		card.z_index = 100
	start_y_enemies = battle.center_position.y - (battle.enemies.size() - 1) * LINE_SPACING * 0.5
	for i in range(battle.enemies.size()):
		var card = battle.enemies[i]
		card.position = Vector2(battle.center_position.x + SIDE_PADDING, start_y_enemies + i * LINE_SPACING)
		card.is_being_dragged = true
		card.z_index = 100

# =======================
# BATTLE COMBAT
# =======================
func process_battle_combat(delta: float) -> void:
	for battle in active_battles.duplicate():
		var all_units = battle.units + battle.enemies
		for card in all_units:
			if not is_instance_valid(card):
				continue
			battle.attack_timers[card] += delta
			var attack_interval = 1.0 / max(card.attack_speed, 0.001)
			if battle.attack_timers[card] >= attack_interval:
				battle.attack_timers[card] = 0.0
				var targets = battle.enemies if card in battle.units else battle.units
				if targets.size() == 0:
					continue
				var target_card = targets[randi() % targets.size()]
				animate_attack(card, target_card)
				var attack_delay = ATTACK_TWEEN_TIME
				await get_tree().create_timer(attack_delay).timeout
				if not is_instance_valid(card) or not is_instance_valid(target_card):
					continue
				var damage = max(card.attack - target_card.armor, 0)
				target_card.set_stat("health", target_card.health - damage)
				if target_card.health <= 0:
					if target_card in battle.units:
						battle.units.erase(target_card)
					if target_card in battle.enemies:
						battle.enemies.erase(target_card)
					var stack = card_manager.find_stack(target_card)
					if stack.size() > 0:
						stack.erase(target_card)
						if stack.size() == 0:
							card_manager.all_stacks.erase(stack)
					target_card.queue_free()
				lock_cards_in_zone(battle)
		if battle.units.is_empty() or battle.enemies.is_empty():
			end_battle(battle)

# =======================
# END BATTLE
# =======================
func end_battle(battle: BattleZone) -> void:
	for card in battle.units + battle.enemies:
		if is_instance_valid(card):
			card.in_battle = false
			card.is_being_dragged = false
			if card_manager.cards_moving.has(card):
				card_manager.cards_moving.erase(card)
	if battle.visual:
		battle.visual.queue_free()
	active_battles.erase(battle)

# =======================
# HELPERS
# =======================
func is_card_in_battle(card: Node2D) -> bool:
	for battle in active_battles:
		if card in battle.units or card in battle.enemies:
			return true
	return false

func calculate_battle_zone_rect(battle: BattleZone) -> Rect2:
	var all_cards = battle.units + battle.enemies
	if all_cards.is_empty():
		return Rect2()
	var rect = card_manager.get_card_global_rect(all_cards[0])
	for i in range(1, all_cards.size()):
		rect = rect.merge(card_manager.get_card_global_rect(all_cards[i]))
	return rect

func animate_attack(attacker: Card, target: Card) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var original_position = attacker.position
	var attack_position = target.position
	var tween = create_tween()
	tween.tween_property(attacker, "position", attack_position, ATTACK_TWEEN_TIME)
	tween.tween_property(attacker, "position", original_position, ATTACK_TWEEN_TIME)

func mark_card_in_battle(card: Card) -> void:
	card.in_battle = true
	card.is_being_dragged = true
	if card_manager.cards_moving.has(card):
		card_manager.cards_moving.erase(card)
