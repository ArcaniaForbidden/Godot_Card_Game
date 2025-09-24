extends Node2D
class_name CraftingManager

# ==============================
#  Crafting Job Class
# ==============================
class CraftingJob:
	var stack_index: int
	var recipe_name: String
	var progress: float = 0.0
	var is_active: bool = true
	var input_cards: Array = []  # actual card instances used
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
	randomize()

func _process(delta: float) -> void:
	update_jobs(delta)
	check_all_stacks_for_recipes()

# ==============================
#  Job Management
# ==============================
func update_jobs(delta: float) -> void:
	for job in active_jobs.duplicate():
		if not job.is_active:
			active_jobs.erase(job)
			continue
		# Fetch the stack
		if job.stack_index >= card_manager.all_stacks.size():
			cancel_job(job)
			continue
		var stack = card_manager.all_stacks[job.stack_index]
		# Cancel if any required input card is missing
		for c in job.input_cards:
			if not is_instance_valid(c) or not stack.has(c):
				cancel_job(job)
				break
		if not job.is_active:
			continue
		# Progress crafting
		var recipe = RecipeDatabase.recipes[job.recipe_name]
		job.progress += delta
		# Throttle debug print
		job.debug_timer += delta
		if debug_show_progress and job.debug_timer >= 0.5:
			print("Crafting '%s' on stack %d: %.2f / %.2f" %
				[job.recipe_name, job.stack_index, job.progress, recipe.work_time])
			job.debug_timer = 0.0  # reset timer
		# Complete if done
		if job.progress >= recipe.work_time:
			complete_job(job)

# ==============================
#  Start a Job
# ==============================
func start_job(stack_index: int, recipe_name: String) -> void:
	if stack_index >= card_manager.all_stacks.size():
		return
	# --- Check if this stack already has an active job ---
	for job in active_jobs:
		if job.stack_index == stack_index and job.is_active:
			return  # already crafting something on this stack
	var stack = card_manager.all_stacks[stack_index]
	var recipe = RecipeDatabase.recipes.get(recipe_name, null)
	if not recipe:
		return
	var matched_cards = stack_matches_recipe(stack, recipe.inputs)
	if matched_cards.size() == 0:
		return  # ingredients not available
	# --- Create the new job ---
	var job = CraftingJob.new()
	job.stack_index = stack_index
	job.recipe_name = recipe_name
	job.input_cards = matched_cards
	active_jobs.append(job)

# ==============================
#  Cancel / Complete Jobs
# ==============================
func complete_job(job: CraftingJob) -> void:
	var stack = card_manager.all_stacks[job.stack_index]
	var recipe = RecipeDatabase.recipes[job.recipe_name]
	# Remove consumed cards
	for input in recipe.inputs:
		if input.get("consume", false):
			var count_to_consume = input.get("count", 1)
			# Iterate over a copy of job.input_cards so we can safely remove items
			for c in job.input_cards.duplicate():
				if count_to_consume <= 0:
					break
				if is_instance_valid(c) and c.subtype == input["subtype"]:
					if c.is_being_dragged:
						card_manager.finish_drag_player()
					stack.erase(c)
					c.queue_free()
					job.input_cards.erase(c)  # remove from job's input list too
					count_to_consume -= 1
	# Spawn output cards
	for output in recipe.outputs:
		var start_pos = Vector2.ZERO
		if stack.size() > 0:
			start_pos = stack[0].position
		var new_card = card_manager.spawn_card(output["subtype"], start_pos)
		if SoundManager:
			SoundManager.play("card_pop", -6.0)
		new_card.is_being_crafted_dragged = true
		print("Spawned '%s' at %s" % [new_card.subtype, start_pos])
		# Check nearby stacks within radius
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
			if top_card.subtype == output["subtype"]:
				var dist = bottom_card.position.distance_to(start_pos)
				print("Checking stack top '%s' at %s, distance = %.2f" % [top_card.subtype, top_card.position, dist])
				if dist < 1:
					continue  # ignore itself
				if dist <= search_radius:
					target_pos = top_card.position
					merge_stack = s
					print("-> Found merge stack at %s" % top_card.position)
					break
		# If no valid merge stack, pick random direction/distance
		if target_pos == null:
			var angle = randf() * PI * 2
			var distance = 200 + randf() * 200  # 200-400 pixels
			target_pos = start_pos + Vector2(cos(angle), sin(angle)) * distance
			print("No nearby stack, moving to random position %s" % target_pos)
		else:
			print("Will merge onto existing stack at %s" % target_pos)
		# Tween card to final position
		new_card.scale = Vector2(1.1, 1.1)
		new_card.z_index = card_manager.DRAG_Z_INDEX
		new_card.is_being_crafted_dragged = true
		# Tween to the target position
		var tween = get_tree().create_tween()
		tween.tween_property(new_card, "position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Optional: you can also tween scale back to 1 after it reaches destination
		tween.finished.connect(Callable(func() -> void:
			if is_instance_valid(new_card):
				new_card.scale = Vector2(1, 1)  # reset scale
				new_card.is_being_crafted_dragged = false
				card_manager.finish_drag_simulated([new_card])
		))
	# Finish job
	job.is_active = false
	if job in active_jobs:
		active_jobs.erase(job)
	print("Job completed: %s" % job.recipe_name)

func cancel_job(job: CraftingJob) -> void:
	job.is_active = false
	active_jobs.erase(job)
	print("Crafting Cancelled: %s" % job.recipe_name)

# ==============================
#  Recipe Matching Helper
# ==============================
func stack_matches_recipe(stack: Array, recipe_inputs: Array) -> Array:
	var temp_stack = stack.duplicate()
	var matched_cards: Array = []
	for input in recipe_inputs:
		var subtype = input["subtype"]
		var consume = input.get("consume", true)
		var found_card = null
		for c in temp_stack:
			if is_instance_valid(c) and c.subtype == subtype:
				found_card = c
				break
		if found_card:
			matched_cards.append(found_card)
			if consume:
				temp_stack.erase(found_card)  # only remove if consumed
		else:
			# Fail if required consumable or required non-consumable is missing
			return []
	return matched_cards

# ==============================
#  Auto-Check All Stacks for Recipes
# ==============================
func check_all_stacks_for_recipes():
	for i in range(card_manager.all_stacks.size()):
		var stack = card_manager.all_stacks[i]
		# Skip if a job is already running on this stack
		var already_running := false
		for job in active_jobs:
			if job.stack_index == i:
				already_running = true
				break
		if already_running:
			continue
		# Check recipes
		for recipe_name in RecipeDatabase.recipes.keys():
			var recipe = RecipeDatabase.recipes[recipe_name]
			var matched = stack_matches_recipe(stack, recipe.inputs)
			if matched.size() > 0:
				start_job(i, recipe_name)
				# Stop checking other recipes for this stack
				break
