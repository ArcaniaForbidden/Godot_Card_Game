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
const BATTLE_ZONE_SIZE := Vector2(300, 200)  # fixed size of the battle zone

# --- Member variables ---
var card_being_dragged: Node2D = null
var dragged_substack: Array = []
var drag_offset: Vector2 = Vector2.ZERO
var original_z_index: int = 0
var all_stacks: Array = []             # Each element is an array of cards
var card_scene = preload("res://Scenes/card.tscn")
var screen_size: Vector2

# Battle & AI
var attack_cooldowns: Dictionary = {}  # card -> cooldown time
var battle_zone: Array = []             # Each element: {"units": [], "enemies": [], "position": Vector2}
var enemy_step_targets: Dictionary = {}
var enemy_step_timers: Dictionary = {}

func _ready() -> void:
	screen_size = get_viewport_rect().size
	spawn_initial_cards()

func _process(delta: float) -> void:
	handle_dragging()
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
	spawn_card("villager", Vector2(400, 300))
	spawn_card("villager", Vector2(400, 200))
	spawn_card("tree", Vector2(500, 300))
	spawn_card("rock", Vector2(600, 300))
	spawn_card("wood", Vector2(700, 300))
	spawn_card("stone", Vector2(800, 300))
	spawn_card("wolf", Vector2(800, 600))
	spawn_card("wolf", Vector2(900, 600))
	spawn_card("wolf", Vector2(1000, 600))

func spawn_card(subtype: String, position: Vector2) -> Node2D:
	var card_instance: Node2D = card_scene.instantiate()
	add_child(card_instance)
	card_instance.position = Vector2(
		clamp(position.x, 0, screen_size.x),
		clamp(position.y, 0, screen_size.y)
	)
	card_instance.setup(subtype)
	card_instance.add_to_group("cards")
	all_stacks.append([card_instance])
	return card_instance

# ==============================
#  DRAG & STACK MANAGEMENT
# ==============================
func handle_mouse_press() -> void:
	var card = raycast_check_for_card()
	if not card:
		return
	if card.card_type != "enemy":
		start_drag(card)
	else:
		print("Cannot drag enemy card:", card.subtype)

func handle_mouse_release() -> void:
	if card_being_dragged:
		finish_drag()

func handle_dragging() -> void:
	if dragged_substack.size() == 0:
		return
	var mouse_pos = get_global_mouse_position()
	for i in range(dragged_substack.size()):
		var card = dragged_substack[i]
		var target_pos = Vector2(
			clamp(mouse_pos.x + drag_offset.x, 0, screen_size.x),
			clamp(mouse_pos.y + drag_offset.y + i * STACK_Y_OFFSET, 0, screen_size.y)
		)
		card.position = card.position.lerp(target_pos, 0.1)
		card.z_index = DRAG_Z_INDEX + i

func start_drag(card: Node2D) -> void:
	if card.in_battle:
		return  # cannot drag cards in battle
	var stack = find_stack(card)
	var index = get_card_index_in_stack(card)
	drag_offset = card.global_position - get_global_mouse_position()
	if index > 0:
		dragged_substack = stack.slice(index, stack.size())
		var remaining_stack = stack.slice(0, index)
		all_stacks.erase(stack)
		all_stacks.append(remaining_stack)
		all_stacks.append(dragged_substack)
		card_being_dragged = dragged_substack[0]
	else:
		dragged_substack = stack
		card_being_dragged = card
	original_z_index = card.z_index
	card.z_index = DRAG_Z_INDEX

func finish_drag() -> void:
	if dragged_substack.size() == 0:
		return
	var card = dragged_substack[0]
	merge_overlapping_stacks(card)
	update_stacks_after_drag()
	dragged_substack.clear()
	card_being_dragged = null

# ==============================
#  ENEMY MOVEMENT
# ==============================
func handle_enemy_movement(delta: float) -> void:
	for stack in all_stacks:
		for card in stack:
			if card.card_type == "enemy":
				move_enemy_step(card, delta)

func move_enemy_step(enemy_card: Node2D, delta: float) -> void:
	# Initialize timer if missing
	if not enemy_step_timers.has(enemy_card):
		enemy_step_timers[enemy_card] = 0.0
	# Countdown timer
	if enemy_step_timers[enemy_card] > 0:
		enemy_step_timers[enemy_card] -= delta
		return
	# Pick new step if no target or reached current target
	if not enemy_step_targets.has(enemy_card) \
	or enemy_card.position.distance_to(enemy_step_targets[enemy_card]) < 5:
		var dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var new_target = enemy_card.position + dir * ENEMY_STEP_DISTANCE
		new_target.x = clamp(new_target.x, 0, screen_size.x)
		new_target.y = clamp(new_target.y, 0, screen_size.y)
		enemy_step_targets[enemy_card] = new_target
		var tween := get_tree().create_tween()
		tween.tween_property(enemy_card, "position", new_target, ENEMY_TWEEN_DURATION) \
			 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Reset timer after moving
		enemy_step_timers[enemy_card] = randf_range(ENEMY_IDLE_MIN, ENEMY_IDLE_MAX)

# ==============================
#  STACK HELPER FUNCTIONS
# ==============================
func merge_overlapping_stacks(card: Node2D) -> void:
	var overlapping = get_overlapping_cards(card, OVERLAP_THRESHOLD)
	if overlapping.size() == 0:
		print("Card", card.subtype, "does not overlap with any other stack.")
		return
	for other_card in overlapping:
		if other_card.card_type == "enemy":
			continue  # Do NOT merge onto enemy cards
		var dragged_stack = find_stack(card)
		var target_stack = find_stack(other_card)
		if dragged_stack != target_stack and target_stack.size() > 0:
			merge_stacks(target_stack, dragged_stack)
			update_stack_visuals(target_stack, target_stack[0].position)
			var names: Array = []
			for c in target_stack:
				names.append(c.subtype)
			print("Merged stack:", names)

func update_stacks_after_drag():
	var new_stacks: Array = []
	for stack in all_stacks:
		var remaining_cards: Array = []
		for card in stack:
			var overlapping = get_overlapping_cards(card, OVERLAP_THRESHOLD)
			overlapping.erase(card)
			if overlapping.size() > 0:
				remaining_cards.append(card)
			else:
				new_stacks.append([card])
		if remaining_cards.size() > 0:
			new_stacks.append(remaining_cards)
	all_stacks = new_stacks
	# Update visuals
	for stack in all_stacks:
		if stack.size() > 0:
			update_stack_visuals(stack, stack[0].position)

func merge_stacks(target_stack: Array, dragged_stack: Array) -> void:
	for c in dragged_stack:
		target_stack.append(c)  # dragged cards go on top
	# Update z_index
	for i in range(target_stack.size()):
		target_stack[i].z_index = i + 1
	all_stacks.erase(dragged_stack)

func update_stack_visuals(stack: Array, base_position: Vector2, y_offset: float = STACK_Y_OFFSET) -> void:
	for i in range(stack.size()):
		var card = stack[i]
		var target_position = Vector2(base_position.x, base_position.y + i * y_offset)
		var tween := get_tree().create_tween()
		tween.tween_property(card, "position", target_position, STACK_TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
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
	var overlapping_cards: Array = []
	var area = card.get_node("Area2D") if card.has_node("Area2D") else null
	if not area:
		return overlapping_cards
	var collision_shape = area.get_node("CollisionShape2D") if area.has_node("CollisionShape2D") else null
	if not collision_shape or not collision_shape.shape:
		return overlapping_cards
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsShapeQueryParameters2D.new()
	parameters.shape_rid = collision_shape.shape.get_rid()
	parameters.transform = collision_shape.get_global_transform()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_shape(parameters, 32)
	var rect_a = get_card_global_rect(card)
	if rect_a.size == Vector2.ZERO:
		return overlapping_cards
	for r in result:
		var other_card = r.collider.get_parent()
		if other_card == card:
			continue
		var rect_b = get_card_global_rect(other_card)
		if rect_b.size == Vector2.ZERO:
			continue
		var intersection = rect_a.intersection(rect_b)
		if intersection.size.x <= 0 or intersection.size.y <= 0:
			continue
		var intersection_area = intersection.size.x * intersection.size.y
		var card_area = rect_a.size.x * rect_a.size.y
		var overlap_percent = (intersection_area / card_area) * 100.0
		if overlap_percent >= min_overlap_percent:
			overlapping_cards.append(other_card)
	return overlapping_cards

func get_card_global_rect(card: Node2D) -> Rect2:
	var area = card.get_node("Area2D") if card.has_node("Area2D") else null
	if not area:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var collision_shape = area.get_node("CollisionShape2D") if area.has_node("CollisionShape2D") else null
	if not collision_shape or not collision_shape.shape:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var shape = collision_shape.shape
	var pos = collision_shape.get_global_position()
	if shape is RectangleShape2D:
		var size = shape.extents * 2
		var top_left = pos - shape.extents
		return Rect2(top_left, size)
	else:
		var aabb = shape.get_rect()
		aabb.position += pos
		return aabb

func is_card_overlapping_zone(card: Node2D, zone: Dictionary) -> bool:
	for u in zone["units"]:
		if u != card and get_card_global_rect(card).intersects(get_card_global_rect(u)):
			return true
	for e in zone["enemies"]:
		if e != card and get_card_global_rect(card).intersects(get_card_global_rect(e)):
			return true
	return false

func calculate_zone_center(cards: Array) -> Vector2:
	if cards.size() == 0:
		return Vector2.ZERO
	var total = Vector2.ZERO
	for c in cards:
		total += c.position
	return total / cards.size()
