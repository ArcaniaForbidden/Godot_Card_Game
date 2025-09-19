extends Node2D

# --- Constants ---
const COLLISION_MASK_CARD := 1
const STACK_Y_OFFSET := 25.0            # Vertical spacing between cards in a stack
const DRAG_Z_INDEX := 100               # Z-index while dragging
const OVERLAP_THRESHOLD := 30.0         # Percent overlap for merging stacks
const ENEMY_STEP_DISTANCE := 150.0      # How far enemies move per step
const ENEMY_IDLE_MIN := 0.8             # Min wait time before next step
const ENEMY_IDLE_MAX := 1.5             # Max wait time before next step
const ENEMY_TWEEN_DURATION := 0.3       # Tween duration for enemy movement
const STACK_TWEEN_DURATION := 0.1       # Tween duration for stack visuals
const PLAY_AREA := Rect2(Vector2(-2000, -1000), Vector2(4000, 2000))

# --- Member variables ---
var card_being_dragged: Node2D = null
var dragged_substack: Array = []
var drag_offset: Vector2 = Vector2.ZERO
var all_stacks: Array = []
var card_scene = preload("res://Scenes/card.tscn")
var battle_manager: Node = null
var job_manager: Node = null
var screen_size: Vector2
var cached_rects: Dictionary = {}  # card -> Rect2
var cards_moving: Dictionary = {}  # card -> target_position
var card_tweens: Dictionary = {}  # card -> SceneTreeTween

func _ready() -> void:
	battle_manager = get_parent().get_node("BattleManager")
	job_manager = get_parent().get_node("JobManager")
	screen_size = get_viewport_rect().size
	spawn_initial_cards()

func _process(delta: float) -> void:
	handle_dragging()
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
	card.connect("inventory_open_requested", Callable($InventoryPanel, "open_inventory"))
	all_stacks.append([card])
	return card

# ==============================
#  DRAG & STACK MANAGEMENT
# ==============================
func handle_mouse_press() -> void:
	var card = raycast_check_for_card()
	if not card:
		return
	if card.in_battle:
		print("Cannot drag card in battle:", card.subtype)
		return
	if card.card_type == "enemy":
		print("Cannot drag enemy card:", card.subtype)
		return
	start_drag(card)

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
		# Safe to access card properties here
		if card.in_battle:
			finish_drag()
			return
		var target_pos: Vector2
		if i == 0:
			# Bottom card follows mouse exactly
			target_pos = mouse_pos + drag_offset
		else:
			# Top cards lag behind previous card
			var prev_card = dragged_substack[i - 1]
			if is_instance_valid(prev_card):
				target_pos = prev_card.position + Vector2(0, STACK_Y_OFFSET)
			else:
				# fallback if previous card was freed
				target_pos = mouse_pos + drag_offset
		# Clamp to play area instead of viewport
		target_pos.x = clamp(target_pos.x, PLAY_AREA.position.x, PLAY_AREA.position.x + PLAY_AREA.size.x)
		target_pos.y = clamp(target_pos.y, PLAY_AREA.position.y, PLAY_AREA.position.y + PLAY_AREA.size.y)
		# Smoothly move toward target
		card.position = card.position.lerp(target_pos, 0.25)
		# Ensure dragged stack appears on top
		card.z_index = DRAG_Z_INDEX + i

func start_drag(card: Card) -> void:
	var stack = find_stack(card)
	var index = get_card_index_in_stack(card)
	if index == -1:
		return  # safety check
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
	# Play card pickup sound
	if SoundManager:
		SoundManager.play("card_pickup", -12.0)
	# Store mouse offset
	drag_offset = dragged_substack[0].position - get_global_mouse_position()
	# Mark cards as being dragged
	for c in dragged_substack:
		c.is_being_dragged = true
	card_being_dragged = dragged_substack[0]
	# Check jobs for all other stacks immediately**
	if job_manager:
		job_manager.check_all_stacks()

func finish_drag() -> void:
	if dragged_substack.size() == 0:
		return
	if SoundManager:
		SoundManager.play("card_drop", -6.0)
	for c in dragged_substack:
		c.is_being_dragged = false
	# Merge stacks only for non-battle cards
	if dragged_substack[0].in_battle == false:
		merge_overlapping_stacks(dragged_substack[0])
	# Update positions of dragged cards
	var base_pos = dragged_substack[0].position
	for i in range(dragged_substack.size()):
		var card = dragged_substack[i]
		if not is_instance_valid(card):
			continue
		var target_pos = base_pos + Vector2(0, i * STACK_Y_OFFSET)
		cards_moving[card] = target_pos
	card_being_dragged = null
	# After releasing, recheck all stacks for jobs
	if job_manager:
		job_manager.check_all_stacks()
	dragged_substack.clear()

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

# ==============================
#  STACK HELPER FUNCTIONS
# ==============================
func merge_overlapping_stacks(card: Node2D) -> void:
	var overlapping = get_overlapping_cards(card, OVERLAP_THRESHOLD)
	if overlapping.size() == 0:
		return
	# Filter out any top cards that are in battle
	overlapping = overlapping.filter(func(entry):
		return not entry["card"].in_battle
	)
	if overlapping.size() == 0:
		return
	# Find the stack with the maximum overlap
	var max_overlap_card = overlapping[0]["card"]
	var max_overlap_value = overlapping[0]["overlap"]
	for entry in overlapping:
		if entry["overlap"] > max_overlap_value:
			max_overlap_card = entry["card"]
			max_overlap_value = entry["overlap"]
	# Merge dragged stack onto this target stack
	var dragged_stack = find_stack(card)
	var target_stack = find_stack(max_overlap_card)
	if dragged_stack != target_stack and target_stack.size() > 0:
		merge_stacks(target_stack, dragged_stack)
		update_stack_visuals(target_stack, target_stack[0].position)

func merge_stacks(target_stack: Array, dragged_stack: Array) -> void:
	# kill tweens on involved cards to avoid conflicts
	for c in target_stack:
		if is_instance_valid(c):
			kill_card_tween(c)
	for c in dragged_stack:
		if is_instance_valid(c):
			kill_card_tween(c)
	# append logically
	for c in dragged_stack:
		if is_instance_valid(c):
			target_stack.append(c)
	# remove old reference
	if all_stacks.has(dragged_stack):
		all_stacks.erase(dragged_stack)
	# snap all cards instantly to correct positions (prevents visual drift)
	if target_stack.size() > 0 and is_instance_valid(target_stack[0]):
		var base_pos = target_stack[0].position
		for i in range(target_stack.size()):
			var card = target_stack[i]
			if is_instance_valid(card):
				card.position = base_pos + Vector2(0, i * STACK_Y_OFFSET)
				card.z_index = i + 1
	# now run the normal visual update (creates new tweens cleanly)
	update_stack_visuals(target_stack, target_stack[0].position)

func update_stack_visuals(stack: Array, base_position: Vector2, y_offset: float = STACK_Y_OFFSET) -> void:
	for i in range(stack.size()):
		var card = stack[i]
		if not is_instance_valid(card):
			continue
		var target_position = Vector2(base_position.x, base_position.y + i * y_offset)
		# kill any existing tween first
		kill_card_tween(card)
		# create a fresh tween and store it
		var tween := get_tree().create_tween()
		tween.tween_property(card, "position", target_position, STACK_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		card_tweens[card] = tween
		# z-order
		card.z_index = i + 1

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

func update_cached_rects() -> void:
	cached_rects.clear()
	var cleaned_stacks: Array = []
	for stack in all_stacks:
		var valid_cards = stack.filter(func(c): return is_instance_valid(c))
		if valid_cards.size() > 0:
			cleaned_stacks.append(valid_cards)
			for card in valid_cards:
				cached_rects[card] = calculate_card_global_rect(card)
	all_stacks = cleaned_stacks  # keep stacks clean

# ==============================
#  UTILITY FUNCTIONS
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

func get_overlapping_cards(card: Node2D, min_overlap_percent := OVERLAP_THRESHOLD) -> Array:
	var overlapping: Array = []
	var rect_a = get_card_global_rect(card)
	if rect_a.size == Vector2.ZERO:
		return overlapping
	for stack in all_stacks:
		if stack == find_stack(card):
			continue
		var top_card = stack[-1]
		if not is_instance_valid(top_card) or top_card.card_type == "enemy":
			continue
		var rect_b = get_card_global_rect(top_card)
		var intersection = rect_a.intersection(rect_b)
		if intersection.size.x > 0 and intersection.size.y > 0:
			var overlap_percent = (intersection.size.x * intersection.size.y) / (rect_a.size.x * rect_a.size.y) * 100.0
			if overlap_percent >= min_overlap_percent:
				overlapping.append({"card": top_card, "overlap": overlap_percent})
	return overlapping

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
#  INVENTORY FUNCTIONS
# ==============================


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
