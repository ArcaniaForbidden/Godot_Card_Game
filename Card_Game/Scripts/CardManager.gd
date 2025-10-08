extends Node2D
class_name CardManager

# --- Constants ---
const COLLISION_MASK_CARD := 1
const STACK_Y_OFFSET := 30.0            # Vertical spacing between cards in a stack
const DRAG_Z_INDEX := 1000              # Z-index while dragging
const OVERLAP_THRESHOLD := 10.0         # Percent overlap for merging stacks
const ENEMY_STEP_DISTANCE := 150.0      # How far enemies move per step
const ENEMY_IDLE_MIN := 0.8             # Min wait time before next step
const ENEMY_IDLE_MAX := 1.5             # Max wait time before next step
const ENEMY_TWEEN_DURATION := 0.3       # Tween duration for enemy movement
const STACK_TWEEN_DURATION := 0.2       # Tween duration for stack visuals
const PUSH_TWEEN_DURATION := 0.025
const PLAY_AREA := Rect2(Vector2(-2000, -1000), Vector2(4000, 2000))
const OUTPUT_MIN_DIST := 100.0
const OUTPUT_MAX_DIST := 150.0
const OUTPUT_TWEEN_TIME := 0.3
const PUSH_STRENGTH := 1000
const PUSH_ITERATIONS := 1
const DOUBLE_CLICK_TIME := 0.3
const PACK_UNLOCK_CHAIN = {
	"plains_card_pack": [5, "forest_card_pack", 10, Vector2(240, -300)],
	"forest_card_pack": [5, "mountain_card_pack", 10, Vector2(360, -300)]
	# add more as needed
}

# --- Member variables ---
var card_being_dragged: Node2D = null
var dragged_substack: Array = []
var drag_offset: Vector2 = Vector2.ZERO
var drag_lift_y: float = -20.0
var last_click_time := 0.0
var last_clicked_card: Card = null
var all_stacks: Array = []
var card_scene = preload("res://Scenes/Card.tscn")
var CardDatabase = preload("res://Scripts/CardDatabase.gd").card_database
var battle_manager: Node = null
var crafting_manager: Node = null
var map_manager: Node = null
var screen_size: Vector2
var cached_rects: Dictionary = {}  # card -> Rect2
var card_tweens: Dictionary = {}   # card -> SceneTreeTween
var allowed_stack_types := {
	"currency": ["currency"],
	"unit": ["unit", "resource", "material", "building", "location"],      # units can stack with other units and equipment
	"equipment": ["unit", "equipment"],                                    # equipment only stacks on equipment or units
	"resource": ["unit", "resource", "material", "building"],
	"material": ["unit", "resource", "material", "building"],
	"enemy": [],                                                           # enemies cannot stack
	"building": ["building", "location"],
	"location": ["location"],
	"card_pack": ["card_pack"],
}

func _ready() -> void:
	battle_manager = get_parent().get_node("BattleManager")
	crafting_manager = get_parent().get_node("CraftingManager")
	map_manager = get_parent().get_node("MapManager")
	screen_size = get_viewport_rect().size
	spawn_initial_cards()
	spawn_initial_slots()

func _process(delta: float) -> void:
	handle_dragging()
	push_apart_cards()
	update_cached_rects()
	handle_enemy_movement(delta)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			handle_mouse_press()
		else:
			handle_mouse_release()

# ==============================
#  CARD SPAWNING
# ==============================
func spawn_initial_cards() -> void:
	spawn_card("peasant", Vector2(0, 0))
	spawn_card("peasant", Vector2(0, 0))
	spawn_card("quarry", Vector2(400,400))
	spawn_card("wooden_spear", Vector2(400,600))
	spawn_card("wooden_spear", Vector2(400,700))
	spawn_card("iron_spear", Vector2(400,800))
	spawn_card("leather_chestplate", Vector2(400,900))
	spawn_card("lumber_camp", Vector2(400,500))
	spawn_card("tree", Vector2(500, 300))
	spawn_card("rock", Vector2(600, 300))
	spawn_card("wood", Vector2(700, 300))
	spawn_card("wood", Vector2(700, 300))
	spawn_card("stone", Vector2(800, 300))
	spawn_card("stone", Vector2(800, 300))
	spawn_card("brick", Vector2(800, 300))
	spawn_card("plank", Vector2(800, 300))
	spawn_card("water", Vector2(800, 300))
	spawn_card("gold_coin", Vector2(900, 300))
	spawn_card("iron_deposit", Vector2(800, 300))
	spawn_card("copper_deposit", Vector2(800, 300))
	spawn_card("gold_deposit", Vector2(800, 300))
	spawn_card("wolf", Vector2(800, 600))
	spawn_card("wolf", Vector2(900, 600))
	spawn_card("wolf", Vector2(1800, 600))
	spawn_card("forest", Vector2(0, 100))
	spawn_card("plains", Vector2(0, 200))
	spawn_card("mountain", Vector2(0, 300))
	spawn_card("cave", Vector2(0, 400))

func spawn_card(subtype: String, position: Vector2) -> Card:
	var card: Card = card_scene.instantiate() as Card
	add_child(card)
	card.position = position
	card.setup(subtype)
	card.is_being_dragged = false
	card.target_position = position
	all_stacks.append([card])
	return card

func spawn_initial_slots() -> void:
	spawn_slot("res://Scenes/SellSlot.tscn", Vector2(0,-300))
	spawn_slot("res://Scenes/PackSlot.tscn", Vector2(120, -300), "plains_card_pack", 10)

func spawn_slot(slot_scene_path: String, position: Vector2, pack_subtype: String = "", pack_cost: int = 0) -> Node2D:
	# Load the scene
	var slot_scene = load(slot_scene_path)
	if not slot_scene:
		push_error("Failed to load slot scene: " + slot_scene_path)
		return null
	var slot_instance = slot_scene.instantiate() as Node2D
	slot_instance.position = position
	add_child(slot_instance)
	# If the slot is a PackSlot, assign pack type and cost
	if slot_instance is PackSlot and pack_subtype != "":
		var pack_slot = slot_instance as PackSlot
		pack_slot.set_pack_type(pack_subtype, pack_cost)
		if pack_cost > 0:
			pack_slot.pack_cost = pack_cost
	# Add to all_stacks so merging/dragging logic works
	all_stacks.append([slot_instance])
	return slot_instance

# ==============================
#  DRAG & DROP
# ==============================
func handle_mouse_press() -> void:
	var clicked_card = raycast_check_for_card()
	if not clicked_card:
		return
	if clicked_card is InventorySlot:
		print("Cannot drag inventory slot:", clicked_card.name)
		return
	if clicked_card is SellSlot:
		print("Cannot drag sell slot:", clicked_card.name)
		return
	if clicked_card is PackSlot:
		print("Cannot drag pack slot:", clicked_card.name)
		return
	if clicked_card.in_battle:
		print("Cannot drag card in battle:", clicked_card.subtype)
		return
	if clicked_card.card_type == "enemy":
		print("Cannot drag enemy card:", clicked_card.subtype)
		return
	if clicked_card.is_being_simulated_dragged:
		return
	var current_time = Time.get_ticks_msec() / 1000.0
	if clicked_card == last_clicked_card and current_time - last_click_time <= DOUBLE_CLICK_TIME:
		if clicked_card.card_type == "card_pack":
			open_card_pack(clicked_card)  # Call your pack opening function
			PlayerProgress.increment_card_pack_opened(clicked_card.subtype)
			if PACK_UNLOCK_CHAIN.has(clicked_card.subtype):
				var threshold = PACK_UNLOCK_CHAIN[clicked_card.subtype][0]
				var next_subtype  = PACK_UNLOCK_CHAIN[clicked_card.subtype][1]
				var next_card_pack_cost = PACK_UNLOCK_CHAIN[clicked_card.subtype][2]
				var next_card_pack_position = PACK_UNLOCK_CHAIN[clicked_card.subtype][3]
				var opened_count = PlayerProgress.card_pack_opened.get(clicked_card.subtype, 0)
				if opened_count >= threshold:
					spawn_slot("res://Scenes/PackSlot.tscn", next_card_pack_position, next_subtype, next_card_pack_cost)
		last_clicked_card = null
		return
	else:
		last_clicked_card = clicked_card
		last_click_time = current_time
	# If not double-click, start dragging normally
	start_drag(clicked_card)

func handle_mouse_release() -> void:
	if card_being_dragged:
		if card_being_dragged.animation_manager:
			card_being_dragged.animation_manager.play_idle()
			finish_drag_player()
	debug_print_stacks()

func handle_dragging() -> void:
	if dragged_substack.size() == 0:
		return
	var mouse_pos = get_global_mouse_position()
	for i in range(dragged_substack.size() - 1, -1, -1):
		var card = dragged_substack[i]
		if not is_instance_valid(card):
			dragged_substack.remove_at(i)
			continue
		var target_pos: Vector2
		if i == 0:
			# Bottom card follows mouse with visual lift
			target_pos = mouse_pos + drag_offset + Vector2(0, drag_lift_y)
		else:
			# Top cards follow previous card naturally
			var prev_card = dragged_substack[i - 1]
			if is_instance_valid(prev_card):
				target_pos = prev_card.position + Vector2(0, STACK_Y_OFFSET)
			else:
				# fallback if previous card was freed
				target_pos = mouse_pos + drag_offset + Vector2(0, drag_lift_y)
		var map_rect = map_manager.map_rect
		target_pos.x = clamp(target_pos.x,
			map_manager.map_rect.position.x,
			map_manager.map_rect.position.x + map_manager.map_rect.size.x)
		target_pos.y = clamp(target_pos.y,
			map_manager.map_rect.position.y,
			map_manager.map_rect.position.y + map_manager.map_rect.size.y)
		# Smoothly move toward target
		card.position = card.position.lerp(target_pos, 0.1)

func start_drag(card: Card) -> void:
	if card.is_equipped and card.attached_slot:
		card.attached_slot.unequip_card()
	var stack = find_stack(card)
	if card.animation_manager:
		card.animation_manager.play_walk()
	var index = get_card_index_in_stack(card)
	if index == -1:
		return
	# Slice substack from clicked card to the top
	dragged_substack = stack.slice(index, stack.size())
	# Remove these cards from original stack
	for i in range(stack.size() - 1, index - 1, -1):
		stack.remove_at(i)
	# Keep remaining stack if non-empty
	if stack.is_empty():
		all_stacks.erase(stack)
	# Add dragged_substack as a new stack in all_stacks
	all_stacks.append(dragged_substack)
	close_stack_inventories(dragged_substack)
	# Play pickup sound
	if SoundManager:
		SoundManager.play("card_pickup", -12.0)
	# Store mouse offset relative to the card's original position
	drag_offset = dragged_substack[0].position - get_global_mouse_position()
	# Mark cards as being dragged, assign high z-index
	for i in range(dragged_substack.size()):
		var c = dragged_substack[i]
		if is_instance_valid(c):
			c.is_being_dragged = true
			c.z_index = DRAG_Z_INDEX + i
			var target_scale = Vector2(1.1, 1.1)
			if c.scale != target_scale:
				kill_card_tween(c) # kill any existing tween
				var tween = get_tree().create_tween()
				tween.tween_property(c, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				card_tweens[c] = tween
	card_being_dragged = dragged_substack[0]

func finish_drag_generic(cards: Array, is_simulated: bool, play_sound: bool = true) -> void:
	if cards.is_empty():
		return
	if play_sound and SoundManager:
		SoundManager.play("card_drop", -6.0)
	# Choose which flag to set/clear
	for c in cards:
		if not is_instance_valid(c):
			continue
		if is_simulated:
			c.is_being_simulated_dragged = true
		else:
			c.is_being_dragged = false
		kill_card_tween(c)
	# Make sure stack membership is clean before merging
	if is_simulated:
		for c in cards:
			var old_stack = find_stack(c)
			if not old_stack.is_empty():
				old_stack.erase(c)
				if old_stack.is_empty():
					all_stacks.erase(old_stack)
	if is_simulated:
		all_stacks.append(cards)
	var bottom_card = cards[0]
	if not is_instance_valid(bottom_card):
		return
	var can_merge = not (not is_simulated and bottom_card.in_battle)
	var merged := false
	if can_merge:
		merged = merge_overlapping_stacks(bottom_card)
	var extra_offset_y = -drag_lift_y if (not merged and not is_simulated) else 0
	# Snap positions (or let tween place them)
	var stack = find_stack(bottom_card)
	if not stack.is_empty():
		if stack[0] is InventorySlot:
			return  # leave slot where it is
		var base_pos = stack[0].global_position if stack[0] is InventorySlot else stack[0].position
		for i in range(stack.size()):
			var card = stack[i]
			if not is_instance_valid(card):
				continue
			var target_pos = base_pos + Vector2(0, i * STACK_Y_OFFSET) + Vector2(0, extra_offset_y)
			if card.is_equipped and card.attached_slot:
				card.global_position = target_pos
				card.scale = Vector2(1, 1)
				card.z_index = i + 1
				continue 
			kill_card_tween(card)
			var tween = get_tree().create_tween()
			tween.tween_property(card, "position", target_pos, STACK_TWEEN_DURATION)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if not (card is InventorySlot):
				tween.parallel().tween_property(card, "scale", Vector2(1, 1), STACK_TWEEN_DURATION)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			card_tweens[card] = tween
			card.z_index = i + 1
	# Clear flags after merge/tween setup
	for c in cards:
		if is_instance_valid(c):
			if is_simulated:
				c.is_being_simulated_dragged = false

func finish_drag_player() -> void:
	finish_drag_generic(dragged_substack, false, true)
	card_being_dragged = null
	dragged_substack.clear()

func finish_drag_simulated(cards_to_place: Array) -> void:
	finish_drag_generic(cards_to_place, true, false)

func merge_overlapping_stacks(card: Node2D) -> bool:
	var overlapping = get_overlapping_cards_any(card, OVERLAP_THRESHOLD)
	if overlapping.size() == 0:
		return false
	var dragged_stack = find_stack(card)
	if dragged_stack.is_empty():
		return false
	var dragged_bottom_card = dragged_stack[0]
	var max_overlap_entry = null
	# --- Find the overlapping stack/slot with the maximum overlap ---
	for entry in overlapping:
		var target_stack = find_stack(entry["card"])
		if target_stack.is_empty():
			continue
		if target_stack.any(func(c): return c.is_equipped if is_instance_valid(c) else false):
			continue
		if max_overlap_entry == null or entry["overlap"] > max_overlap_entry["overlap"]:
			max_overlap_entry = entry
	if max_overlap_entry == null:
		return false
	var target_stack = find_stack(max_overlap_entry["card"])
	if target_stack.is_empty():
		return false
	var target_top_card = target_stack[-1]
	var target_bottom_card = target_stack[0]
	# --- Special case: InventorySlot ---
	if target_top_card is InventorySlot:
		if dragged_stack.size() > 1:
			return false
		var inventory_slot = target_top_card as InventorySlot
		if inventory_slot.can_accept_card(dragged_bottom_card):
			inventory_slot.equip_card(dragged_bottom_card)
			if all_stacks.has(dragged_stack):
				all_stacks.erase(dragged_stack)
			return true
	# --- Special case: SellSlot ---
	if target_top_card is SellSlot:
		for c in dragged_stack:
			if not is_instance_valid(c) or c.value <= 0:
				return false  # skip this stack, continue normal merging
		target_top_card.sell_stack(dragged_stack)
		dragged_stack.clear()
		return true
	# --- Special case: PackSlot ---
	if target_top_card is PackSlot:
		var card_added := false
		for i in range(dragged_substack.size() - 1, -1, -1):
			var c = dragged_substack[i]
			if not is_instance_valid(c):
				continue
			if c.card_type == "currency":
				target_top_card.add_value(c)
				dragged_substack.remove_at(i)  # remove immediately
				card_added = true
		return card_added
		# Remove only the cards that were accepted
		dragged_stack = dragged_stack.filter(func(c): return is_instance_valid(c) and c.card_type != "currency")
		return card_added
	# --- Skip if top card is being dragged ---
	if target_bottom_card.is_being_dragged:
		return false
	# --- Validate stack types ---
	var dragged_type = dragged_bottom_card.card_type
	var target_type = target_top_card.card_type
	if not allowed_stack_types.has(dragged_type):
		return false
	if not target_type in allowed_stack_types[dragged_type]:
		return false
	# --- Merge stacks ---
	for c in target_stack:
		if is_instance_valid(c):
			kill_card_tween(c)
	for c in dragged_stack:
		if is_instance_valid(c):
			kill_card_tween(c)
			target_stack.append(c)
	if all_stacks.has(dragged_stack):
		all_stacks.erase(dragged_stack)
	# --- Snap positions and recalc z-index ---
	if target_stack.size() > 0 and is_instance_valid(target_stack[0]):
		close_stack_inventories(target_stack)
		var base_pos = target_stack[0].position
		for i in range(target_stack.size()):
			var c = target_stack[i]
			if is_instance_valid(c):
				var target_pos = base_pos + Vector2(0, i * STACK_Y_OFFSET)
				kill_card_tween(c)
				var tween = get_tree().create_tween()
				tween.tween_property(c, "position", target_pos, STACK_TWEEN_DURATION)\
					.set_trans(Tween.TRANS_QUAD)\
					.set_ease(Tween.EASE_OUT)
				card_tweens[c] = tween
				c.z_index = i + 1
	return true

func stack_has_simulated_dragged(stack: Array) -> bool:
	for card in stack:
		if is_instance_valid(card) and card.is_being_simulated_dragged:
			return true
	return false

# ==============================
#  CARD MOVEMENT UPDATES
# ==============================
func push_apart_cards() -> void:
	if all_stacks.size() < 2:
		return
	# --- Precompute stack bounds, centers, and stack center positions ---
	var stack_bounds := []
	var stack_card_centers := []
	var stack_center_x := []
	var card_rects := {}  # cache rects for this frame
	for stack in all_stacks:
		if stack.is_empty() or not is_instance_valid(stack[0]) \
			or stack.has(card_being_dragged) or stack[0].card_type == "enemy" \
			or stack[0] is InventorySlot  or stack[0] is SellSlot or stack[0] is PackSlot\
			or stack_has_simulated_dragged(stack) \
			or stack.any(func(c): return c.is_equipped if is_instance_valid(c) else false):
			stack_bounds.append(null)
			stack_card_centers.append(null)
			stack_center_x.append(INF)  # sentinel
			continue
		var bounds = get_stack_bounds(stack)
		stack_bounds.append(bounds)
		var centers := []
		for card in stack:
			if is_instance_valid(card):
				var rect: Rect2
				if card_rects.has(card):
					rect = card_rects[card]
				else:
					rect = get_card_global_rect(card)
					card_rects[card] = rect
				centers.append(rect.position + rect.size / 2)
			else:
				centers.append(Vector2.ZERO)
		stack_card_centers.append(centers)
		stack_center_x.append(bounds.position.x + bounds.size.x * 0.5)  # center x
	# --- Compare each stack pair ---
	for i in range(all_stacks.size()):
		var stack_a = all_stacks[i]
		var bounds_a = stack_bounds[i]
		var centers_a = stack_card_centers[i]
		if not bounds_a:
			continue
		for j in range(i + 1, all_stacks.size()):
			var stack_b = all_stacks[j]
			var bounds_b = stack_bounds[j]
			var centers_b = stack_card_centers[j]
			if not bounds_b:
				continue
			if stack_b[0].card_type == "enemy":
				continue
			# --- Quick center-to-center prefilter ---
			var center_dist = abs(stack_center_x[i] - stack_center_x[j])
			if center_dist > 100:  # tweak margin to cover possible overlap
				continue
			var push_vector := Vector2.ZERO
			var overlap_found := false
			# --- Detailed per-card check ---
			for a_index in range(stack_a.size()):
				var card_a = stack_a[a_index]
				if not is_instance_valid(card_a):
					continue
				var rect_a = card_rects[card_a]
				var center_a = centers_a[a_index]
				for b_index in range(stack_b.size()):
					var card_b = stack_b[b_index]
					if not is_instance_valid(card_b):
						continue
					var rect_b = card_rects[card_b]
					var center_b = centers_b[b_index]
					if rect_a.intersects(rect_b):
						overlap_found = true
						var intersection = rect_a.intersection(rect_b)
						var dir = center_a - center_b
						if dir == Vector2.ZERO:
							dir = Vector2.RIGHT
						push_vector += dir.normalized() * clamp((intersection.size.x * intersection.size.y) / (rect_a.size.x * rect_a.size.y), 0.1, 1.0)
			if overlap_found:
				push_vector = push_vector.limit_length(PUSH_STRENGTH)
				var delta = get_process_delta_time()
				var push_amount = push_vector * PUSH_STRENGTH * delta
				for c in stack_a:
					if is_instance_valid(c) and not c.is_being_dragged:
						c.position += push_amount
				for c in stack_b:
					if is_instance_valid(c) and not c.is_being_dragged:
						c.position -= push_amount

func update_cached_rects() -> void:
	cached_rects.clear()
	var cleaned_stacks: Array = []
	for stack in all_stacks:
		var valid_cards = []
		for card in stack:
			if is_instance_valid(card):
				valid_cards.append(card)
				# calculate and store global rect only once
				cached_rects[card] = calculate_card_global_rect(card)
		if valid_cards.size() > 0:
			cleaned_stacks.append(valid_cards)
	all_stacks = cleaned_stacks

func get_stack_bounds(stack: Array) -> Rect2:
	if stack.is_empty():
		return Rect2()
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	for c in stack:
		if not is_instance_valid(c):
			continue 
		var rect = get_card_global_rect(c)
		min_x = min(min_x, rect.position.x)
		min_y = min(min_y, rect.position.y)
		max_x = max(max_x, rect.position.x + rect.size.x)
		max_y = max(max_y, rect.position.y + rect.size.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

# ==============================
#  STACK HELPERS
# ==============================
func find_stack(card: Node2D) -> Array:
	for stack in all_stacks:
		if card in stack:
			return stack
	return []

func get_card_index_in_stack(card: Node2D) -> int:
	var stack = find_stack(card)
	if stack.size() == 0:
		return -1
	return stack.find(card)

func close_stack_inventories(stack: Array) -> void:
	for card in stack:
		if not is_instance_valid(card):
			continue
		var inventory = card.get_node_or_null("PeasantInventory")
		if inventory:
			var container = inventory.get_node_or_null("InventoryContainer")
			if container:
				container.visible = false
			for slot in inventory.slot_cards:
				slot.visible = false
				if slot.attached_card and is_instance_valid(slot.attached_card):
					slot.attached_card.visible = false

# ==============================
#  UTILITIES & HELPERS
# ==============================
func raycast_check_for_card() -> Node2D:
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var visible_cards := []
		for r in result:
			var card = r.collider.get_parent()
			if is_instance_valid(card) and card.is_visible_in_tree():
				visible_cards.append(r)
		if visible_cards.size() == 0:
			return null
		return get_card_with_highest_z_index(visible_cards)
	return null

func get_card_with_highest_z_index(cards: Array) -> Node2D:
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if not is_instance_valid(current_card) or not current_card.is_visible_in_tree():
			continue
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

func get_overlapping_cards_any(card: Node2D, min_overlap_percent := OVERLAP_THRESHOLD) -> Array:
	var overlapping_cards: Array = []
	var dragged_rect = get_card_global_rect(card)
	if dragged_rect.size == Vector2.ZERO:
		return overlapping_cards
	for stack in all_stacks:
		if stack == find_stack(card):
			continue
		if stack.size() == 0:
			continue
		for target_card in stack:
			if not is_instance_valid(target_card):
				continue
			var target_rect = get_card_global_rect(target_card)
			var intersection = dragged_rect.intersection(target_rect)
			if intersection.size.x > 0 and intersection.size.y > 0:
				var overlap_percent = (intersection.size.x * intersection.size.y) / (dragged_rect.size.x * dragged_rect.size.y) * 100.0
				if overlap_percent >= min_overlap_percent:
					overlapping_cards.append({"card": target_card, "overlap": overlap_percent})
					break
	return overlapping_cards

func get_card_global_rect(card: Node2D) -> Rect2:
	if not is_instance_valid(card):
		return Rect2()
	if cached_rects.has(card):
		return cached_rects[card]
	var rect = calculate_card_global_rect(card)
	cached_rects[card] = rect
	return rect

func calculate_card_global_rect(card: Node2D) -> Rect2:
	if not is_instance_valid(card):
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	if cached_rects.has(card):
		return cached_rects[card]
	var area = card.get_node_or_null("Area2D")
	if not area:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var collision_shape = area.get_node_or_null("CollisionShape2D")
	if not collision_shape or not collision_shape.shape:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var shape = collision_shape.shape
	var pos = collision_shape.get_global_position()
	var rect = Rect2()
	if shape is RectangleShape2D:
		var size = shape.extents * 2
		rect = Rect2(pos - shape.extents, size)
	else:
		var aabb = shape.get_rect()
		aabb.position += pos
		rect = aabb
	cached_rects[card] = rect
	return rect

func kill_card_tween(card: Node2D) -> void:
	if card_tweens.has(card):
		var t = card_tweens[card]
		if t and t.is_running():
			t.kill()
		card_tweens.erase(card)

func get_weighted_loot(loot_table: Array) -> String:
	var total_weight := 0
	for item in loot_table:
		total_weight += item.weight
	var r = randf() * total_weight
	var accum = 0.0
	for item in loot_table:
		accum += item.weight
		if r <= accum:
			return item.subtype
	return loot_table[-1].subtype # fallback

func open_card_pack(pack_card: Card, num_cards := 5) -> void:
	if not is_instance_valid(pack_card) or pack_card.card_type != "card_pack":
		return
	if not CardDatabase.has(pack_card.subtype):
		return
	var pack_data = CardDatabase[pack_card.subtype]
	if not pack_data.has("loot_table"):
		return
	for i in range(num_cards):
		var loot_subtype = get_weighted_loot(pack_data["loot_table"])
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		spawn_card(loot_subtype, pack_card.global_position + offset)
	var stack = find_stack(pack_card)
	if stack and stack.has(pack_card):
		stack.erase(pack_card)
		if stack.is_empty():
			all_stacks.erase(stack)
	if SoundManager:
		SoundManager.play("card_pack_open", 0.0)
	pack_card.queue_free()

func debug_print_stacks() -> void:
	print("---- All Stacks ----")
	for i in range(all_stacks.size()):
		var stack = all_stacks[i]
		var names: Array = []
		for card in stack:
			if is_instance_valid(card):
				names.append(card.subtype) # or .display_name_label.text if you prefer
			else:
				names.append("<invalid>")
		print("Stack %d: %s" % [i, names])
	print("--------------------")

# ==============================
#  ENEMY MOVEMENT
# ==============================
func handle_enemy_movement(delta: float) -> void:
	for stack in all_stacks:
		var top_card = stack[-1]
		if not is_instance_valid(top_card):
			continue
		if top_card.card_type != "enemy":
			continue
		# Skip enemies in battles
		if battle_manager.is_card_in_battle(top_card):
			continue
		var enemy = top_card
		# decrement idle timer
		enemy.enemy_idle_timer -= delta
		if enemy.enemy_idle_timer <= 0:
			# pick random target within distance
			var range = enemy.enemy_jump_distance
			var target_pos = enemy.position + Vector2(randf_range(-range, range), randf_range(-range, range))
			# Clamp to play area instead of viewport
			target_pos.x = clamp(target_pos.x, PLAY_AREA.position.x, PLAY_AREA.position.x + PLAY_AREA.size.x)
			target_pos.y = clamp(target_pos.y, PLAY_AREA.position.y, PLAY_AREA.position.y + PLAY_AREA.size.y)
			# jump tween
			var tween = get_tree().create_tween()
			tween.tween_property(enemy, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# reset idle timer randomly
			enemy.enemy_idle_timer = randf_range(enemy.enemy_min_jump_time, enemy.enemy_max_jump_time)
