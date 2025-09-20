extends Node2D
class_name JobManager

# --- References ---
var card_manager: Node = null
var battle_manager: Node = null
var RecipeDatabase = preload("res://Scripts/RecipeDatabase.gd")

const PROGRESS_BAR_OFFSET := Vector2(-50, -100)  # above the bottom card
const PROGRESS_BAR_SIZE := Vector2(100, 20)
const OUTPUT_MIN_DIST := 100.0
const OUTPUT_MAX_DIST := 150.0
const OUTPUT_TWEEN_TIME := 0.3

# --- Active jobs ---
# each job = { "stack": Array, "recipe": Dictionary, "progress": float, "work_time": float }
var active_jobs: Array = []
var stack_progress: Dictionary = {}  # stack -> progress (0.0 to 1.0)

func _ready() -> void:
	card_manager = get_parent().get_node("CardManager")
	if get_parent().has_node("BattleManager"):
		battle_manager = get_parent().get_node("BattleManager")
	else:
		battle_manager = null
	print("JobManager ready. Loaded recipes:")
	for recipe_name in RecipeDatabase.recipes.keys():
		var r = RecipeDatabase.recipes[recipe_name]
		var names: Array = []
		if r.has("inputs"):
			for i in r["inputs"]:
				names.append(i["subtype"])
		print("- %s : %s" % [recipe_name, names])

func _process(delta: float) -> void:
	update_jobs(delta)
	for job in active_jobs:
		update_job_progress_bar(job)

# -----------------------------
# Check all stacks for new/invalid jobs
# -----------------------------
func check_all_stacks() -> void:
	var dragged_stack: Array = []
	if card_manager and card_manager.card_being_dragged != null:
		dragged_stack = card_manager.dragged_substack
	# Cancel invalid jobs
	var to_cancel: Array = []
	for job in active_jobs:
		var tracked_stack: Array = job["stack"]
		# Skip if it's the dragged stack
		if tracked_stack == dragged_stack:
			continue
		var still_present := false
		for st in card_manager.all_stacks:
			if st == tracked_stack:
				still_present = true
				break
		if not still_present or not is_stack_matching_recipe(tracked_stack, job["recipe"]):
			to_cancel.append(job)
	for job in to_cancel:
		cancel_job(job)
	# Detect new jobs
	for stack in card_manager.all_stacks:
		if stack.size() == 0 or stack == dragged_stack:
			continue
		if is_stack_job_active(stack):
			continue
		for recipe_name in RecipeDatabase.recipes.keys():
			var recipe_data = RecipeDatabase.recipes[recipe_name]
			if is_stack_matching_recipe(stack, recipe_data):
				start_job(stack, recipe_name, recipe_data)
				break

# -----------------------------
# Update jobs each frame
# -----------------------------
func update_jobs(delta: float) -> void:
	for job in active_jobs.duplicate():
		var stack: Array = job["stack"]
		var recipe: Dictionary = job["recipe"]
		# --- 0) If the tracked stack no longer exists in all_stacks -> cancel ---
		var stack_still_registered := false
		for st in card_manager.all_stacks:
			if st == stack:
				stack_still_registered = true
				break
		if not stack_still_registered:
			print("⏹ Job canceled (tracked stack removed). Recipe:", job["recipe_name"], "Tracked stack:", stack_to_names(stack))
			remove_progress_bar(job)
			active_jobs.erase(job)
			continue
		# --- 1) If any required card is gone/invalid or in battle -> cancel ---
		var should_cancel := false
		for c in stack:
			if not is_instance_valid(c):
				should_cancel = true
				break
			if "in_battle" in c and c.in_battle:
				should_cancel = true
				break
			if battle_manager and battle_manager.has_method("is_card_in_battle"):
				if battle_manager.is_card_in_battle(c):
					should_cancel = true
					break
		if should_cancel:
			var names: Array = []
			for c in stack:
				if is_instance_valid(c):
					names.append(c.subtype)
			print("⏹ Job canceled (card removed or entered battle). Stack:", names, "Recipe:", job["recipe_name"])
			remove_progress_bar(job)
			active_jobs.erase(job)
			continue
		# --- 2) If stack no longer exactly matches the recipe -> cancel ---
		if not is_stack_matching_recipe(stack, recipe):
			var names2: Array = []
			for c in stack:
				names2.append(c.subtype)
			print("⏹ Job canceled (stack no longer matches). Stack:", names2, "Recipe:", job["recipe_name"])
			remove_progress_bar(job)
			active_jobs.erase(job)
			continue
		# --- 3) Still valid -> increment progress ---
		job["progress"] += delta
		# --- 4) Throttled progress print (every 0.5s) ---
		job["__progress_print_timer"] = job.get("__progress_print_timer", 0.0) + delta
		if job["__progress_print_timer"] >= 0.5:
			var progress_names: Array = []
			for c in stack:
				progress_names.append(c.subtype)
			print("Job progress:", str(snapped(job["progress"], 0.01)), "/", job["work_time"], 
				  "Stack:", progress_names, 
				  "Recipe:", job["recipe_name"])  # use stored recipe_name
			job["__progress_print_timer"] = 0.0
		# --- 5) Completion ---
		if job["progress"] >= job["work_time"]:
			var progress_names2: Array = []
			for c in stack:
				progress_names2.append(c.subtype)
			print("✅ Job complete! Recipe:", job["recipe_name"], "Stack:", progress_names2)
			# --- 5a) Consume inputs (safe removal + drag fix) ---
			var inputs: Array = recipe["inputs"]
			# We'll remove from highest index to lowest so stack indices remain valid
			for i in range(inputs.size() - 1, -1, -1):
				if inputs[i].get("consume", true):
					if i < stack.size() and is_instance_valid(stack[i]):
						var removed_card = stack[i]
						# If CardManager exists, remove references from dragged_substack BEFORE freeing
						if card_manager:
							# Remove all occurrences of removed_card from dragged_substack
							for j in range(card_manager.dragged_substack.size() - 1, -1, -1):
								if card_manager.dragged_substack[j] == removed_card:
									card_manager.dragged_substack.remove_at(j)
						# Now remove from the stack and free the node
						stack.remove_at(i)
						removed_card.queue_free()
			# --- 5b) After consuming inputs: fix drag state if needed ---
			if card_manager:
				# If nothing left being dragged -> ensure drag finishes cleanly
				if card_manager.dragged_substack.size() == 0:
					# Only call finish_drag if card_manager thinks we're dragging
					if card_manager.card_being_dragged != null:
						card_manager.finish_drag()
				else:
					# We are still dragging some cards — rebind drag state to the new bottom card
					# Set the card_being_dragged to new bottom and recompute drag_offset so it stays attached naturally.
					var new_bottom = card_manager.dragged_substack[0]
					# Safety: ensure new_bottom is valid
					if is_instance_valid(new_bottom):
						card_manager.card_being_dragged = new_bottom
						# Recompute offset relative to current mouse position (use CardManager's Node2D method)
						# card_manager is Node2D so it has get_global_mouse_position()
						if card_manager.has_method("get_global_mouse_position"):
							card_manager.drag_offset = new_bottom.position - card_manager.get_global_mouse_position()
						else:
							# fallback: zero offset
							card_manager.drag_offset = Vector2.ZERO
						# Mark remaining cards as being dragged and refresh z-index so they draw on top
						for k in range(card_manager.dragged_substack.size()):
							var c = card_manager.dragged_substack[k]
							if is_instance_valid(c):
								c.is_being_dragged = true
								# keep z ordering consistent with CardManager's DRAG_Z_INDEX (if present)
								if card_manager.has_method("DRAG_Z_INDEX") == false and "DRAG_Z_INDEX" in card_manager:
									# (unlikely) but try property access
									c.z_index = int(card_manager.DRAG_Z_INDEX) + k
								elif "DRAG_Z_INDEX" in card_manager:
									c.z_index = int(card_manager.DRAG_Z_INDEX) + k
								else:
									# fallback: large z
									c.z_index = 100 + k
			# --- 5c) Produce outputs ---
			var default_sound = "card_pop"
			var default_volume_db = -8.0
			if "outputs" in recipe:
				for output_dict in recipe["outputs"]:
					var subtype = output_dict["subtype"]
					var amount = output_dict.get("amount", 1)
					for t_i in range(amount):
						# spawn with sound and volume
						spawn_card_with_popout(stack, subtype, default_sound, default_volume_db)
			elif "loot_table" in recipe:
				# Spawn one item from the loot table with sound
				spawn_loot_table_outputs(stack, recipe["loot_table"], default_sound, default_volume_db)
			# --- 5d) Finalize job removal and re-check stacks ---
			remove_progress_bar(job)
			active_jobs.erase(job)
			check_all_stacks()

# -----------------------------
# Matching logic
# -----------------------------
func is_stack_matching_recipe(stack: Array, recipe: Dictionary) -> bool:
	var inputs: Array = recipe["inputs"]
	if stack.size() != inputs.size():
		return false
	for i in range(inputs.size()):
		if stack[i].subtype != inputs[i]["subtype"]:
			return false
	return true

func is_stack_job_active(stack: Array) -> bool:
	for job in active_jobs:
		if job["stack"] == stack:
			return true
	return false

func start_job(stack: Array, recipe_name: String, recipe_data: Dictionary) -> void:
	var job := {
		"stack": stack,
		"recipe": recipe_data,
		"recipe_name": recipe_name,
		"progress": 0.0,
		"work_time": recipe_data.get("work_time", 5.0)
	}
	job["progress_bar"] = create_progress_bar(stack)
	active_jobs.append(job)
	print("▶ Job started. Stack:", stack_to_names(stack), "Recipe:", recipe_name)

func cancel_job(job: Dictionary) -> void:
	print("⏹ Job canceled. Stack:", stack_to_names(job["stack"]), "Recipe:", job["recipe_name"])
	remove_progress_bar(job)
	if job in active_jobs:
		active_jobs.erase(job)

func stack_to_names(stack: Array) -> Array:
	var names: Array = []
	for c in stack:
		if is_instance_valid(c):
			names.append(c.subtype)
	return names

# -----------------------------
# Progress bar
# -----------------------------
func create_progress_bar(stack: Array) -> Control:
	# Create the background bar
	var bar_bg = ColorRect.new()
	bar_bg.color = Color.WHITE
	bar_bg.size = PROGRESS_BAR_SIZE
	bar_bg.name = "JobProgressBar"
	# Create the fill bar
	var fill = ColorRect.new()
	fill.name = "Fill"
	fill.color = Color.BLACK
	fill.size = Vector2(0, PROGRESS_BAR_SIZE.y)  # start empty
	fill.position = Vector2.ZERO
	bar_bg.add_child(fill)
	# Add the progress bar to the current scene
	get_tree().current_scene.add_child(bar_bg)
	# Position it above the bottom card
	update_progress_bar_position(bar_bg, stack)
	return bar_bg

func update_progress_bar_position(bar: Control, stack: Array) -> void:
	if stack.size() > 0 and is_instance_valid(stack[0]):
		var bottom_card = stack[0]
		bar.global_position = bottom_card.global_position + PROGRESS_BAR_OFFSET

func update_job_progress_bar(job: Dictionary) -> void:
	if not job.has("progress_bar"): 
		return
	if not is_instance_valid(job["progress_bar"]):
		return
	var bar: ColorRect = job["progress_bar"]
	var fill: ColorRect = bar.get_node("Fill")
	# Update fill size based on progress
	var ratio = clamp(job["progress"] / job["work_time"], 0, 1)
	fill.size.x = PROGRESS_BAR_SIZE.x * ratio
	# Also reset the white bar to full size every frame (so it moves and scales together)
	bar.size = PROGRESS_BAR_SIZE
	# Update position above the bottom card
	update_progress_bar_position(bar, job["stack"])

func remove_progress_bar(job: Dictionary) -> void:
	if job.has("progress_bar"):
		var bar = job["progress_bar"]
		if is_instance_valid(bar):
			bar.queue_free()
		job.erase("progress_bar")

# -----------------------------
# Helpers
# -----------------------------
func spawn_card_with_popout(stack: Array, subtype: String, sound: String = "", volume_db: float = -6.0) -> void:
	if stack.size() == 0:
		return
	var origin = stack[0].global_position
	var new_card = card_manager.spawn_card(subtype, origin)
	stack.append(new_card)
	# Random direction + distance
	var angle = randf() * TAU
	var distance = randf_range(OUTPUT_MIN_DIST, OUTPUT_MAX_DIST)
	var target_pos = origin + Vector2(cos(angle), sin(angle)) * distance
	# Tween the card
	var tween = get_tree().create_tween()
	tween.tween_property(new_card, "position", target_pos, OUTPUT_TWEEN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if card_manager.card_tweens:
		card_manager.card_tweens[new_card] = tween
	print("Produced output:", new_card.subtype, "on stack (popped out)")
	# Play the sound if provided
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
