extends Node2D
class_name CardManager

# --- Constants ---
const COLLISION_MASK_CARD := 1
const STACK_Y_OFFSET := 25.0            # Vertical spacing between cards in a stack
const DRAG_Z_INDEX := 100               # Z-index while dragging
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
const PUSH_STRENGTH := 20
const PUSH_ITERATIONS := 1

# --- Member variables ---
var card_being_dragged: Node2D = null
var dragged_substack: Array = []
var drag_offset: Vector2 = Vector2.ZERO
var all_stacks: Array = []
var spawn_protected_cards: Array = []
var card_scene = preload("res://Scenes/Card.tscn")
var battle_manager: Node = null
var job_manager: Node = null
var screen_size: Vector2
var cached_rects: Dictionary = {}  # card -> Rect2
var stack_bounds_cache := {}
var cards_moving: Dictionary = {}  # card -> target_position
var card_tweens: Dictionary = {}   # card -> SceneTreeTween
var allowed_stack_types := {
	"unit": ["unit", "resource", "material", "building", "location"],      # units can stack with other units and equipment
	"equipment": ["unit", "equipment"],                                    # equipment only stacks on equipment or units
	"resource": ["unit", "resource", "material", "building"],
	"material": ["unit", "resource", "material", "building"],
	"enemy": [],                                                           # enemies cannot stack
	"building": ["building"],
	"location": []
}

func _ready() -> void:
	battle_manager = get_parent().get_node("BattleManager")
	job_manager = get_parent().get_node("JobManager")
	screen_size = get_viewport_rect().size
	spawn_initial_cards()

func _process(delta: float) -> void:
	handle_dragging()
	push_apart_cards()
	update_cached_rects()
	handle_enemy_movement(delta)
	update_cards_moving(delta)

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
	spawn_card("peasant", Vector2(400, 300))
	spawn_card("peasant", Vector2(400, 200))
	spawn_card("quarry", Vector2(400,400))
	spawn_card("wooden_spear", Vector2(400,600))
	spawn_card("wooden_spear", Vector2(400,700))
	spawn_card("iron_spear", Vector2(400,800))
	spawn_card("lumber_camp", Vector2(400,500))
	spawn_card("tree", Vector2(500, 300))
	spawn_card("rock", Vector2(600, 300))
	spawn_card("wood", Vector2(700, 300))
	spawn_card("wood", Vector2(700, 300))
	spawn_card("stone", Vector2(800, 300))
	spawn_card("stone", Vector2(800, 300))
	spawn_card("wolf", Vector2(800, 600))
	spawn_card("wolf", Vector2(900, 600))
	spawn_card("wolf", Vector2(1800, 600))
	spawn_card("forest", Vector2(0, 100))

func spawn_card(subtype: String, position: Vector2) -> Card:
	var card: Card = card_scene.instantiate() as Card
	add_child(card)
	card.position = position
	card.setup(subtype)
	card.is_being_dragged = false
	card.target_position = position
	all_stacks.append([card])
	return card

func spawn_card_with_popout(stack: Array, subtype: String, sound: String = "", volume_db: float = -6.0) -> void:
	if stack.size() == 0:
		return
	var origin = stack[0].global_position
	# Start card *at the stack center*, no offset yet
	var new_card = spawn_card(subtype, origin)
	stack.append(new_card)
	# Protect this card from push_apart until its popout animation finishes
	spawn_protected_cards.append(new_card)
	# Compute where we want it to end up (offset outward from origin)
	var angle = randf() * TAU
	var distance = randf_range(OUTPUT_MIN_DIST, OUTPUT_MAX_DIST)
	var target_pos = origin + Vector2(cos(angle), sin(angle)) * distance
	# Animate: start small, scale up & slide outward simultaneously
	new_card.scale = Vector2.ZERO
	var tween = get_tree().create_tween()
	tween.tween_property(new_card, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(new_card, "position", target_pos, OUTPUT_TWEEN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# store tween if you are tracking them
	card_tweens[new_card] = tween
	# When tween finishes, unprotect card so push_apart works again
	tween.connect("finished", Callable(self, "_on_spawn_popout_finished").bind(new_card))
	print("Produced output:", new_card.subtype, "on stack (popped out)")
	if sound != "" and SoundManager:
		SoundManager.play(sound, volume_db)

func spawn_loot_table_outputs(stack: Array, loot_table: Array, sound: String = "", volume_db: float = -6.0) -> void:
	var total_weight = 0
	for entry in loot_table:
		total_weight += entry.get("weight", 0)
	if total_weight <= 0:
		return
	var roll = randf() * total_weight
	for entry in loot_table:
		roll -= entry.get("weight", 0)
		if roll <= 0:
			for out in entry.get("outputs", []):
				spawn_card_with_popout(stack, out["subtype"], sound, volume_db)
			break

func _on_spawn_popout_finished(card: Node2D) -> void:
	if card in spawn_protected_cards:
		spawn_protected_cards.erase(card)

func stack_has_protected_card(stack: Array) -> bool:
	for c in stack:
		if c in spawn_protected_cards:
			return true
	return false

# ==============================
#  DRAG & DROP
# ==============================
func handle_mouse_press() -> void:
	var clicked_card = raycast_check_for_card()
	if not clicked_card:
		return  # No card clicked, nothing else to do
	if clicked_card.in_battle:
		print("Cannot drag card in battle:", clicked_card.subtype)
		return
	if clicked_card.card_type == "enemy":
		print("Cannot drag enemy card:", clicked_card.subtype)
		return
	start_drag(clicked_card)

func handle_mouse_release() -> void:
	if card_being_dragged:
		finish_drag()
	# debug_print_stacks()

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
			target_pos = mouse_pos + drag_offset
		else:
			var prev_card = dragged_substack[i - 1]
			target_pos = prev_card.position + Vector2(0, STACK_Y_OFFSET)
		card.position = card.position.lerp(target_pos, 0.25)
		# High z-index only for dragged stack
		card.z_index = DRAG_Z_INDEX + i

func start_drag(card: Card) -> void:
	var stack = find_stack(card)
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
	# Play pickup sound
	if SoundManager:
		SoundManager.play("card_pickup", -12.0)
	# Store mouse offset
	drag_offset = dragged_substack[0].position - get_global_mouse_position()
	# Mark cards as being dragged and assign high z-index
	for i in range(dragged_substack.size()):
		var c = dragged_substack[i]
		c.is_being_dragged = true
		c.z_index = 1000 + i   # HIGH z-index ensures dragged stack is visually on top
	card_being_dragged = dragged_substack[0]
	# Re-check jobs
	if job_manager:
		job_manager.check_all_stacks()

func finish_drag() -> void:
	if dragged_substack.size() == 0:
		return
	if SoundManager:
		SoundManager.play("card_drop", -6.0)
	# Stop dragging state
	for c in dragged_substack:
		if is_instance_valid(c):
			c.is_being_dragged = false
	# Merge overlapping stacks
	if dragged_substack[0].in_battle == false:
		merge_overlapping_stacks(dragged_substack[0])
	# Snap dragged stack to top card's position
	var stack = find_stack(dragged_substack[0])
	if stack.size() > 0:
		var base_pos = stack[0].position
		for i in range(stack.size()):
			var card = stack[i]
			if not is_instance_valid(card):
				continue
			var target_pos = base_pos + Vector2(0, i * STACK_Y_OFFSET)
			kill_card_tween(card)
			var tween = get_tree().create_tween()
			tween.tween_property(card, "position", target_pos, STACK_TWEEN_DURATION)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_OUT)
			card_tweens[card] = tween
			card.z_index = i + 1
	# Clear drag
	card_being_dragged = null
	dragged_substack.clear()
	# Re-check jobs
	if job_manager:
		job_manager.check_all_stacks()

func merge_overlapping_stacks(card: Node2D) -> void:
	var overlapping = get_overlapping_cards_any(card, OVERLAP_THRESHOLD)
	if overlapping.size() == 0:
		return
	var dragged_stack = find_stack(card)
	if dragged_stack.is_empty():
		return
	var dragged_bottom_card = dragged_stack[0]
	# --- Find the overlapping stack with the maximum overlap ---
	var max_overlap_entry = null
	for entry in overlapping:
		var target_stack = find_stack(entry["card"])
		if target_stack.is_empty():
			continue
		var target_top_card = target_stack[-1]
		var dragged_type = dragged_bottom_card.card_type
		var target_type = target_top_card.card_type
		if not allowed_stack_types.has(dragged_type):
			continue
		if not target_type in allowed_stack_types[dragged_type]:
			continue
		if max_overlap_entry == null or entry["overlap"] > max_overlap_entry["overlap"]:
			max_overlap_entry = entry
	if max_overlap_entry == null:
		return
	# --- Merge with the stack that has the maximum overlap ---
	var target_stack = find_stack(max_overlap_entry["card"])
	# Kill tweens for smooth merge
	for c in dragged_stack:
		if is_instance_valid(c):
			kill_card_tween(c)
	for c in target_stack:
		if is_instance_valid(c):
			kill_card_tween(c)
	# Append dragged stack to target stack
	for c in dragged_stack:
		if is_instance_valid(c):
			target_stack.append(c)
	if all_stacks.has(dragged_stack):
		all_stacks.erase(dragged_stack)
	# Snap positions and recalc z-index
	if target_stack.size() > 0 and is_instance_valid(target_stack[0]):
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

# ==============================
#  CARD MOVEMENT UPDATES
# ==============================
func update_cards_moving(delta: float) -> void:
	var finished_cards: Array = []
	for card in cards_moving.keys():
		# Skip if card is no longer valid
		if not is_instance_valid(card):
			finished_cards.append(card)
			continue
		var target_pos = cards_moving[card]
		card.position = card.position.lerp(target_pos, 0.15)
		if card.position.distance_to(target_pos) < 1.0:
			finished_cards.append(card)
	# Remove finished or invalid cards from cards_moving
	for card in finished_cards:
		cards_moving.erase(card)

func push_apart_cards() -> void:
	if all_stacks.size() < 2:
		return
	# --- Precompute stack bounds & card centers ---
	var stack_bounds := []
	var stack_card_centers := []
	for stack in all_stacks:
		if stack.is_empty() or stack_has_protected_card(stack) or stack.has(card_being_dragged):
			stack_bounds.append(null)
			stack_card_centers.append(null)
			continue
		stack_bounds.append(get_stack_bounds(stack))
		var centers := []
		for card in stack:
			if is_instance_valid(card):
				var rect = get_card_global_rect(card)
				centers.append(rect.position + rect.size / 2)
			else:
				centers.append(Vector2.ZERO)
		stack_card_centers.append(centers)
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
			# Skip distant stacks
			if not bounds_a.intersects(bounds_b.grow(50.0)):
				continue
			var push_vector := Vector2.ZERO
			var overlap_found := false
			for a_index in range(stack_a.size()):
				var card_a = stack_a[a_index]
				if not is_instance_valid(card_a) or card_a in spawn_protected_cards:
					continue
				var rect_a = get_card_global_rect(card_a)
				var center_a = centers_a[a_index]
				for b_index in range(stack_b.size()):
					var card_b = stack_b[b_index]
					if not is_instance_valid(card_b) or card_b in spawn_protected_cards:
						continue
					var rect_b = get_card_global_rect(card_b)
					var center_b = centers_b[b_index]
					if rect_a.intersects(rect_b):
						overlap_found = true
						var intersection = rect_a.intersection(rect_b)
						var dir = center_a - center_b
						if dir == Vector2.ZERO:
							dir = Vector2.RIGHT
						push_vector += dir.normalized() * clamp((intersection.size.x * intersection.size.y) / (rect_a.size.x * rect_a.size.y), 0.1, 1.0)
			if overlap_found:
				push_vector *= PUSH_STRENGTH
				# Apply gradual movement
				for c in stack_a:
					if is_instance_valid(c) and not c.is_being_dragged and not (c in spawn_protected_cards):
						c.position = c.position.lerp(c.position + push_vector, 0.5)
				for c in stack_b:
					if is_instance_valid(c) and not c.is_being_dragged and not (c in spawn_protected_cards):
						c.position = c.position.lerp(c.position - push_vector, 0.5)

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

func update_stack_bounds(stack: Array) -> void:
	if stack.is_empty():
		stack_bounds_cache.erase(stack)
	else:
		stack_bounds_cache[stack] = get_stack_bounds(stack)

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
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards: Array) -> Node2D:
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

func get_overlapping_cards_any(card: Node2D, min_overlap_percent := OVERLAP_THRESHOLD) -> Array:
	var overlapping_cards: Array = []  # renamed to avoid conflict
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
