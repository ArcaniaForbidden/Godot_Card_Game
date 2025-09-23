extends Node
class_name CraftingManager

const SEARCH_RADIUS := 200.0
const LAUNCH_OFFSET := 150.0
const LAUNCH_ANGLE_DEG := 10.0
const LAUNCH_TWEEN_TIME := 0.3

# ----------------------
# Member Variables
# ----------------------
var jobs: Array = []  # Each job: {core_bottom: Card, core_top: Card, recipe: Dictionary, time_elapsed: float, last_print: float}
var card_manager: CardManager = null
var recipe_database = preload("res://Scripts/RecipeDatabase.gd")
var print_interval: float = 0.5  # seconds

func _ready() -> void:
	card_manager = get_parent().get_node("CardManager") as CardManager

func _process(delta: float) -> void:
	# Iterate backwards to allow removal
	for i in range(jobs.size() - 1, -1, -1):
		var job = jobs[i]
		var stack = card_manager.find_stack(job.core_bottom)
		# Cancel job if stack is invalid
		if not _validate_job_stack(stack, job):
			print("Crafting job canceled:", job.recipe)
			_stop_drag_if_needed(stack)
			jobs.remove_at(i)
			continue
		# Increment elapsed time
		job.time_elapsed += delta
		# Print progress at interval
		job.last_print += delta
		if job.last_print >= print_interval:
			print("Job progress:", job.time_elapsed, "/", job.recipe.get("work_time", 0), "for recipe:", job.recipe)
			job.last_print = 0
		# Complete job if elapsed time reached
		if job.time_elapsed >= job.recipe.get("work_time", 0):
			_complete_job(stack, job)
			jobs.remove_at(i)

# ----------------------
# Public Functions
# ----------------------
func validate_all_stacks() -> void:
	if not card_manager:
		return
	# Validate running jobs
	for i in range(jobs.size() - 1, -1, -1):
		var job = jobs[i]
		var stack = card_manager.find_stack(job.core_bottom)
		if not _validate_job_stack(stack, job):
			print("Crafting job canceled:", job.recipe)
			_stop_drag_if_needed(stack)
			jobs.remove_at(i)
	# Check each stack for new recipes
	for stack in card_manager.all_stacks:
		_try_run_recipes_for_stack(stack)

# ----------------------
# Internal Helpers
# ----------------------
func _try_run_recipes_for_stack(stack: Array) -> void:
	if stack.size() < 2:
		return
	var bottom_card = stack[0]
	var top_card = stack[-1]
	for recipe_name in recipe_database.recipes.keys():
		var recipe = recipe_database.recipes[recipe_name]
		if not recipe.has("inputs") or recipe["inputs"].size() < 2:
			continue
		var inputs = recipe["inputs"]
		var first_input_type = inputs[0].get("role", "bottom")
		var second_input_type = inputs[1].get("role", "top")
		var is_match = false
		# Match top-core or bottom-core recipes
		if first_input_type == "bottom" and second_input_type == "top":
			if inputs[0]["subtype"] == bottom_card.subtype and inputs[1]["subtype"] == top_card.subtype:
				is_match = true
		elif first_input_type == "top" and second_input_type == "bottom":
			if inputs[0]["subtype"] == top_card.subtype and inputs[1]["subtype"] == bottom_card.subtype:
				is_match = true
		if not is_match:
			continue
		# Check for additional consumables
		var needed = _collect_needed_inputs(recipe, 2, inputs.size())
		if _can_fulfill_consumables(needed, stack):
			_start_job(bottom_card, top_card, recipe)
			break

func _start_job(core_bottom: Node2D, core_top: Node2D, recipe: Dictionary) -> void:
	for job in jobs:
		if job.core_bottom == core_bottom and job.core_top == core_top and job.recipe == recipe:
			return
	var job = {
		"core_bottom": core_bottom,
		"core_top": core_top,
		"recipe": recipe,
		"time_elapsed": 0.0,
		"last_print": 0.0
	}
	jobs.append(job)

func _complete_job(stack: Array, job: Dictionary) -> void:
	if not stack or stack.size() == 0:
		return
	# Validate before completion
	if not _validate_job_stack(stack, job):
		print("Job invalid at completion, skipping:", job.recipe)
		return
	var recipe = job.recipe
	# Remove consumed cards safely
	var inputs = recipe.get("inputs", [])
	var consumed_indices = []
	for i in range(inputs.size()):
		if inputs[i].get("consume", false):
			for j in range(stack.size()):
				if stack[j].subtype == inputs[i]["subtype"]:
					consumed_indices.append(j)
					break
	consumed_indices.sort()
	for i in range(consumed_indices.size() - 1, -1, -1):
		var idx = consumed_indices[i]
		if idx >= 0 and idx < stack.size():
			var card = stack[idx]
			stack.remove_at(idx)
			if is_instance_valid(card):
				# Remove shadow first
				if card.shadow and is_instance_valid(card.shadow):
					card.shadow.queue_free()
				# Stop dragging if this card was being dragged
				if card_manager.dragged_substack.has(card):
					card_manager.finish_drag()
				card.queue_free()
	# Spawn outputs as new stacks
	if recipe.has("outputs"):
		for out in recipe["outputs"]:
			_spawn_crafting_output(out["subtype"], stack[0].global_position)
	# After completion, immediately re-check the stack for repeated crafting
	if stack.size() >= 2:
		_try_run_recipes_for_stack(stack)

func _collect_needed_inputs(recipe: Dictionary, start_idx: int, end_idx: int) -> Array:
	var needed: Array = []
	var inputs = recipe.get("inputs", [])
	for i in range(start_idx, end_idx):
		needed.append(inputs[i])
	return needed

func _can_fulfill_consumables(needed: Array, stack: Array) -> bool:
	var temp_stack = stack.duplicate()
	for need in needed:
		var found = false
		for i in range(temp_stack.size()):
			if temp_stack[i].subtype == need["subtype"]:
				found = true
				temp_stack.remove_at(i)
				break
		if not found:
			return false
	return true

func _validate_job_stack(stack: Array, job: Dictionary) -> bool:
	if not stack or stack.size() < 2:
		return false
	if stack[0] != job.core_bottom or stack[-1] != job.core_top:
		return false
	var temp_stack = stack.duplicate()
	temp_stack.remove_at(temp_stack.size() - 1)  # remove top core
	temp_stack.remove_at(0)                     # remove bottom core
	var inputs = job.recipe.get("inputs", [])
	for i in range(2, inputs.size()):
		var input_dict = inputs[i]
		var found = false
		for j in range(temp_stack.size()):
			if temp_stack[j].subtype == input_dict["subtype"]:
				found = true
				temp_stack.remove_at(j)
				break
		if not found:
			return false
	return true

func _stop_drag_if_needed(stack: Array) -> void:
	# Stop dragging if any card in this stack is being dragged
	if card_manager.dragged_substack.size() > 0:
		for c in stack:
			if c in card_manager.dragged_substack:
				card_manager.finish_drag()
				break
