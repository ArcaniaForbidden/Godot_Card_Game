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
	# --- Check if this stack already has an active job ---
	for job in active_jobs:
		if job.stack == stack and job.is_active:
			return
	var recipe = RecipeDatabase.recipes.get(recipe_name, null)
	if not recipe:
		return
	var matched_cards = stack_matches_recipe(stack, recipe.inputs)
	if matched_cards.size() == 0:
		return
	# --- Create the new job ---
	var job = CraftingJob.new()
	job.stack = stack
	job.recipe_name = recipe_name
	job.input_cards = matched_cards
	active_jobs.append(job)

func update_jobs(delta: float) -> void:
	var remaining_jobs: Array = []
	for job in active_jobs:
		if not job.is_active:
			continue
		# --- Cancel if any card in the stack is being dragged ---
		var dragging := false
		for c in job.stack:
			if is_instance_valid(c) and c.is_being_dragged:
				print("Cancelling job '%s': card being dragged" % job.recipe_name)
				dragging = true
				break
		if dragging:
			cancel_job(job)
			continue 
		# --- Validate stack still contains required input cards ---
		var stack_found := false
		for s in card_manager.all_stacks:
			var all_inputs_present := true
			for input_card in job.input_cards:
				if not s.has(input_card):
					all_inputs_present = false
					break
			if all_inputs_present:
				stack_found = true
				job.stack = s # update reference to current stack
				break
		if not stack_found:
			print("Cancelling job '%s': required cards missing" % job.recipe_name)
			cancel_job(job)
			continue
		# --- Validate stack still matches recipe ---
		var recipe = RecipeDatabase.recipes.get(job.recipe_name, null)
		if recipe == null:
			cancel_job(job)
			continue
		var current_match = stack_matches_recipe(job.stack, recipe.inputs)
		if current_match.size() == 0:
			print("Cancelling job '%s': stack no longer matches recipe" % job.recipe_name)
			cancel_job(job)
			continue
		# --- Progress crafting ---
		job.progress += delta
		job.debug_timer += delta
		if debug_show_progress and job.debug_timer >= 0.5:
			print("Job '%s' progress: %.2f / %.2f" % [
				job.recipe_name,
				job.progress,
				recipe.work_time
			])
			job.debug_timer = 0.0
		if job.progress >= recipe.work_time:
			complete_job(job)
			continue
		# Keep the job alive for the next frame
		remaining_jobs.append(job)
	# Replace old job list with only still-active jobs
	active_jobs = remaining_jobs

func cancel_job(job: CraftingJob) -> void:
	if not job.is_active:
		return
	job.is_active = false
	if job in active_jobs:
		active_jobs.erase(job)
	print("Crafting Cancelled: %s" % job.recipe_name)

func complete_job(job: CraftingJob) -> void:
	var stack = job.stack
	var recipe = RecipeDatabase.recipes.get(job.recipe_name, {})
	# Remove consumed cards
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
	# Determine outputs
	var outputs = recipe.get("outputs", [])
	# Handle loot table if present
	if recipe.has("loot_table"):
		var loot_rolls = recipe.get("loot_table", [])
		if loot_rolls.size() > 0:
			var total_weight = 0
			for entry in loot_rolls:
				total_weight += entry.get("weight", 1)
			var r = randi() % total_weight
			for entry in loot_rolls:
				r -= entry.get("weight", 1)
				if r < 0:
					outputs = entry.get("outputs", [])
					break
	# Spawn output cards
	for output in outputs:
		var subtype = output.get("subtype", "")
		var start_pos = Vector2.ZERO
		if stack.size() > 0:
			start_pos = stack[0].position
		var new_card = card_manager.spawn_card(subtype, start_pos)
		if SoundManager:
			SoundManager.play("card_pop", -4.0)
		new_card.is_being_crafted_dragged = true
		print("Spawned '%s' at %s" % [subtype, start_pos])
		# Find nearby stack to merge
		var target_pos = null
		var merge_stack = null
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
					merge_stack = s
					break
		# Pick random position if no merge stack found
		if target_pos == null:
			var angle = randf() * PI * 2
			var distance = 200 + randf() * 200
			target_pos = start_pos + Vector2(cos(angle), sin(angle)) * distance
		# Tween card to final position
		new_card.scale = Vector2(1.1, 1.1)
		new_card.z_index = card_manager.DRAG_Z_INDEX
		new_card.is_being_crafted_dragged = true
		var tween = get_tree().create_tween()
		tween.tween_property(new_card, "position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(Callable(func() -> void:
			if is_instance_valid(new_card):
				new_card.scale = Vector2(1, 1)
				new_card.is_being_crafted_dragged = false
				card_manager.finish_drag_simulated([new_card])
		))
	# Finish job
	job.is_active = false
	if job in active_jobs:
		active_jobs.erase(job)
	print("Job completed: %s" % job.recipe_name)

# ==============================
#  Recipe Matching Helper
# ==============================
func stack_matches_recipe(stack: Array, recipe_inputs: Array) -> Array:
	if stack.size() < recipe_inputs.size():
		return []
	var matched_cards: Array = []
	for i in range(recipe_inputs.size()):
		var card = stack[i]
		var input = recipe_inputs[i]
		if not is_instance_valid(card) or card.subtype != input["subtype"]:
			return []  # mismatch
		matched_cards.append(card)
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
