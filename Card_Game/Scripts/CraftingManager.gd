extends Node2D
class_name CraftingManager

# ==============================
#  Crafting Job Class
# ==============================
class CraftingJob:
	var stack: Array
	var recipe_name: String
	var progress: float = 0.0
	var is_active: bool = true
	var input_cards: Array = []
	var progress_bar: Control = null
	var progress_bar_sprite: AnimatedSprite2D = null
	var progress_bar_label: Label = null
	var debug_timer: float = 0.0

# ==============================
#  Member Variables 
# ==============================
var active_jobs: Array = []
var card_manager: CardManager = null

# Optional: show progress for debugging
var debug_show_progress := true

# ==============================
#  Initialization
# ==============================
func _ready() -> void:
	card_manager = get_parent().get_node("CardManager") as CardManager

func _process(delta: float) -> void:
	update_jobs(delta)
	check_all_stacks_for_recipes()

# ==============================
#  Job Management
# ==============================
func start_job(stack: Array, recipe_name: String) -> void:
	# prevent duplicate jobs
	for job in active_jobs:
		if job.stack == stack and job.is_active:
			return
	var recipe = RecipeDatabase.recipes.get(recipe_name, null)
	if not recipe:
		print("❌ Recipe not found:", recipe_name)
		return
	var matched_cards = stack_matches_recipe(stack, recipe.inputs)
	if matched_cards.is_empty():
		print("❌ No matched cards for recipe:", recipe_name)
		return
	var job = CraftingJob.new()
	job.stack = stack
	job.recipe_name = recipe_name
	job.input_cards = matched_cards
	active_jobs.append(job)
	# --- Instantiate progress bar Control ---
	var progress_scene = preload("res://Scenes/ProgressBar.tscn")
	var progress_bar = progress_scene.instantiate() as Control
	job.progress_bar = progress_bar
	# Parent to top card if available, else self
	var parent_node: Node
	if stack.size() > 0 and is_instance_valid(stack[0]):
		parent_node = stack[0]
	else:
		parent_node = self
	parent_node.add_child(progress_bar)
	progress_bar.position = Vector2(0, -80)
	progress_bar.z_index = stack.size() > 0 and stack[0].z_index or 0
	progress_bar.visible = true
	# Grab children nodes
	job.progress_bar_sprite = progress_bar.get_node("AnimatedSprite2D") as AnimatedSprite2D
	job.progress_bar_label = progress_bar.get_node("Label") as Label
	# Initialize visuals
	if job.progress_bar_sprite:
		job.progress_bar_sprite.frame = 0
	if job.progress_bar_label:
		job.progress_bar_label.text = str(int(ceil(recipe.work_time))) + "s"
		job.progress_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		job.progress_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	print("✅ Started job:", recipe_name)

func update_jobs(delta: float) -> void:
	var remaining_jobs: Array = []
	var jobs_to_complete: Array = []
	var jobs_to_cancel: Array = []
	for job in active_jobs:
		if not job.is_active:
			continue
		# Cancel if any card is being dragged
		var dragging := false
		for c in job.stack:
			if is_instance_valid(c) and c.is_being_dragged:
				dragging = true
				break
		if dragging:
			jobs_to_cancel.append(job)
			continue 
		# Validate stack still has all input cards
		var stack_found := false
		for s in card_manager.all_stacks:
			var all_inputs_present := true
			for input_card in job.input_cards:
				if not s.has(input_card):
					all_inputs_present = false
					break
			if all_inputs_present:
				stack_found = true
				job.stack = s
				break
		if not stack_found:
			jobs_to_cancel.append(job)
			continue
		# Progress crafting
		job.progress += delta
		job.debug_timer += delta
		if debug_show_progress and job.debug_timer >= 0.5:
			print("Job '%s' progress: %.2f / %.2f" % [
				job.recipe_name,
				job.progress,
				RecipeDatabase.recipes[job.recipe_name].work_time
			])
			job.debug_timer = 0.0
		if job.progress_bar and is_instance_valid(job.progress_bar):
			update_job_progress_bar(job)
		var recipe_time = RecipeDatabase.recipes[job.recipe_name].work_time
		if job.progress >= recipe_time:
			jobs_to_complete.append(job)
		else:
			remaining_jobs.append(job)
	# Cancel jobs safely
	for job in jobs_to_cancel:
		cancel_job(job)
	active_jobs = remaining_jobs
	# Complete jobs
	for job in jobs_to_complete:
		complete_job(job)

func cancel_job(job: CraftingJob) -> void:
	if not job.is_active:
		return
	job.is_active = false
	if job in active_jobs:
		active_jobs.erase(job)
	# Remove progress bar safely
	if job.progress_bar:
		if is_instance_valid(job.progress_bar):
			job.progress_bar.queue_free()
	job.progress_bar = null
	job.progress_bar_sprite = null
	job.progress_bar_label = null
	print("❌ Crafting Cancelled: %s" % job.recipe_name)

func complete_job(job: CraftingJob) -> void:
	var stack = job.stack
	var recipe = RecipeDatabase.recipes.get(job.recipe_name, {})
	# --- Remove consumed cards ---
	for input in recipe.get("inputs", []):
		if input.get("consume", false):
			var count_to_consume = input.get("count", 1)
			for c in job.input_cards.duplicate():
				if count_to_consume <= 0:
					break
				if is_instance_valid(c) and c.subtype == input.get("subtype", ""):
					if c.is_being_dragged:
						card_manager.finish_drag_player()
					if stack.has(c):
						stack.erase(c)
					c.queue_free()
					job.input_cards.erase(c)
					count_to_consume -= 1
	# --- Fix positions of remaining cards in the stack ---
	if stack.size() > 0:
		var base_pos = stack[0].position
		for i in range(stack.size()):
			var card = stack[i]
			if is_instance_valid(card):
				var target_pos = base_pos + Vector2(0, i * card_manager.STACK_Y_OFFSET)
				card_manager.kill_card_tween(card)
				var tween = get_tree().create_tween()
				tween.tween_property(card, "position", target_pos, card_manager.STACK_TWEEN_DURATION)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				card.z_index = i + 1
				card_manager.card_tweens[card] = tween
	# --- Determine outputs ---
	var outputs = recipe.get("outputs", [])
	if recipe.has("loot_table"):
		var loot_rolls = recipe.get("loot_table", [])
		if loot_rolls.size() > 0:
			var valid_loot := []
			for entry in loot_rolls:
				var req = entry.get("requirement", null)
				var passes := true
				if req:
					passes = false
					if req.has("subtype") and PlayerProgress.card_acquired.get(req["subtype"], 0) >= req.get("amount", 1):
						passes = true
					if req.has("recipe_name") and PlayerProgress.recipes_completed.get(req["recipe_name"], 0) >= req.get("amount", 1):
						passes = true
				if passes:
					valid_loot.append(entry)
			if valid_loot.size() > 0:
				var total_weight = 0
				for entry in valid_loot:
					total_weight += entry.get("weight", 1)
				var r = randi() % total_weight
				for entry in valid_loot:
					r -= entry.get("weight", 1)
					if r < 0:
						outputs = entry.get("outputs", [])
						break
	# --- Spawn output cards ---
	for output in outputs:
		var subtype = output.get("subtype", "")
		var start_pos = Vector2.ZERO
		if stack.size() > 0:
			start_pos = stack[0].position
		var new_card = card_manager.spawn_card(subtype, start_pos)
		PlayerProgress.increment_card_count(subtype)
		new_card.is_being_simulated_dragged = true
		print("Spawned '%s' at %s" % [subtype, start_pos])
		# Find nearby stack to merge
		var target_pos = null
		var search_radius = 400
		for s in card_manager.all_stacks:
			if s == stack or s.size() == 0:
				continue
			var top_card = s[s.size() - 1]
			var bottom_card = s[0]
			if not is_instance_valid(top_card) or not is_instance_valid(bottom_card):
				continue
			if bottom_card.is_being_dragged:
				continue
			if top_card.subtype == subtype:
				var dist = bottom_card.position.distance_to(start_pos)
				if dist < 1:
					continue
				if dist <= search_radius:
					target_pos = top_card.position
					break
		# Pick random position if no merge stack found
		if target_pos == null:
			var angle = randf() * PI * 2
			var distance = 200 + randf() * 100
			target_pos = start_pos + Vector2(cos(angle), sin(angle)) * distance
		# Tween card to final position
		new_card.scale = Vector2(1.1, 1.1)
		new_card.z_index = card_manager.DRAG_Z_INDEX
		new_card.is_being_simulated_dragged = true
		var tween_pos = get_tree().create_tween()
		tween_pos.tween_property(new_card, "position", target_pos, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# --- Scale tween (up then down) ---
		var tween_scale = get_tree().create_tween()
		tween_scale.tween_property(new_card, "scale", Vector2(1.25, 1.25), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_scale.tween_property(new_card, "scale", Vector2(1.1, 1.1), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# --- Finish callback ---
		tween_pos.finished.connect(Callable(func() -> void:
			if is_instance_valid(new_card):
				new_card.is_being_simulated_dragged = false
				card_manager.finish_drag_simulated([new_card])
		))
	# --- Finish job ---
	PlayerProgress.increment_recipe(job.recipe_name)
	if SoundManager:
		SoundManager.play("card_pop", -4.0)
	job.is_active = false
	if job in active_jobs:
		active_jobs.erase(job)
	if job.progress_bar:
		if is_instance_valid(job.progress_bar):
			job.progress_bar.queue_free()
	job.progress_bar = null
	job.progress_bar_sprite = null
	job.progress_bar_label = null
	job.is_active = false
	if job in active_jobs:
		active_jobs.erase(job)
	print("✅ Job completed: %s" % job.recipe_name)

# ==============================
#  Recipe Matching Helper
# ==============================
func stack_matches_recipe(stack: Array, recipe_inputs: Array) -> Array:
	if stack.size() < recipe_inputs.size():
		return []
	var matched_cards: Array = []
	var stack_copy = stack.duplicate()
	# Step 1: Match non-consumed cards in order
	var index = 0
	for input in recipe_inputs:
		if input.get("consume", false):
			continue
		if index >= stack_copy.size():
			return []
		var card = stack_copy[index]
		if not is_instance_valid(card) or card.subtype != input["subtype"]:
			return []  # non-consumed mismatch
		matched_cards.append(card)
		stack_copy.remove_at(index)  # remove matched card from copy
	# Step 2: Match consumed cards anywhere in remaining stack
	for input in recipe_inputs:
		if not input.get("consume", false):
			continue
		var found = false
		for card in stack_copy:
			if is_instance_valid(card) and card.subtype == input["subtype"]:
				matched_cards.append(card)
				stack_copy.erase(card)
				found = true
				break
		if not found:
			return []  # required consumed card not found
	return matched_cards

# ==============================
#  Auto-Check All Stacks for Recipes
# ==============================
func check_all_stacks_for_recipes():
	for stack in card_manager.all_stacks:
		# Skip if a job is already running on this stack
		var already_running := false
		for job in active_jobs:
			if job.stack == stack:
				already_running = true
				break
		if already_running:
			continue
		# Find the longest matching recipe
		var best_recipe_name := ""
		var best_match: Array = []
		for recipe_name in RecipeDatabase.recipes.keys():
			var recipe = RecipeDatabase.recipes[recipe_name]
			var matched = stack_matches_recipe(stack, recipe.inputs)
			if matched.size() > best_match.size():
				best_match = matched
				best_recipe_name = recipe_name
		if best_match.size() > 0:
			start_job(stack, best_recipe_name)

# ==============================
#  Public Helper
# ==============================
func is_stack_crafting(stack: Array) -> bool:
	for job in active_jobs:
		if job.stack == stack and job.is_active:
			return true
	return false

func update_job_progress_bar(job: CraftingJob) -> void:
	if not job.progress_bar or not is_instance_valid(job.progress_bar):
		return
	var recipe_time = RecipeDatabase.recipes[job.recipe_name].work_time
	var remaining_time = max(recipe_time - job.progress, 0.0)
	var fraction = clamp(job.progress / recipe_time, 0.0, 1.0)
	# --- Update sprite frame ---
	var total_frames = 10
	var frame = int(floor(fraction * (total_frames - 1)))
	var sprite = job.progress_bar.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.frame = frame
	# --- Update label text ---
	var label = job.progress_bar.get_node("Label") as Label
	if label:
		label.text = str(int(ceil(remaining_time))) + "s"
