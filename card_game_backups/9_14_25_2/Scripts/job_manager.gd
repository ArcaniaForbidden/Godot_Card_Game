extends Node2D
class_name JobManager

# --- References ---
var card_manager: Node = null
var battle_manager: Node = null
var RecipeDatabase = preload("res://Scripts/recipe_database.gd")

# --- Constants ---
const PROGRESS_BAR_OFFSET := Vector2(-50, -100)  # above the bottom card
const PROGRESS_BAR_SIZE := Vector2(100, 20)
const OUTPUT_MIN_DIST := 100.0
const OUTPUT_MAX_DIST := 150.0
const OUTPUT_TWEEN_TIME := 0.3

# --- Job tracking ---
var active_jobs: Array = []

func _ready() -> void:
	card_manager = get_parent().get_node("CardManager")
	if get_parent().has_node("BattleManager"):
		battle_manager = get_parent().get_node("BattleManager")
	else:
		battle_manager = null
	print("JobManager ready. Loaded recipes:")
	for r in RecipeDatabase.recipes:
		var names: Array = []
		for i in r.get("inputs", []):
			names.append(i.get("subtype", "?"))
		print("- %s : %s" % [r.get("name", "?"), names])

func _process(delta: float) -> void:
	update_jobs(delta)
	for job in active_jobs:
		update_job_progress_bar(job)

# -----------------------------
# Check stacks for new/invalid jobs
# -----------------------------
func check_all_stacks() -> void:
	# Cancel invalid jobs first
	for job in active_jobs.duplicate():
		if not is_job_still_valid(job):
			cancel_job(job)
	# Detect new jobs
	for stack in card_manager.all_stacks:
		if stack.is_empty() or is_stack_job_active(stack):
			continue
		for recipe in RecipeDatabase.recipes:
			if does_stack_match_recipe(stack, recipe):
				start_job(stack, recipe)
				break

# -----------------------------
# Job validation
# -----------------------------
func is_job_still_valid(job: Dictionary) -> bool:
	var stack: Array = job.get("stack", [])
	var recipe: Dictionary = job.get("recipe", {})
	if not stack_in_all_stacks(stack):
		return false
	for c in stack:
		if not is_instance_valid(c):
			return false
		if "in_battle" in c and c.in_battle:
			return false
		if battle_manager and battle_manager.has_method("is_card_in_battle"):
			if battle_manager.is_card_in_battle(c):
				return false
	if not does_stack_match_recipe(stack, recipe):
		return false
	return true

func stack_in_all_stacks(stack: Array) -> bool:
	for st in card_manager.all_stacks:
		if st == stack:
			return true
	return false

# -----------------------------
# Stack / Recipe Matching (strict order)
# -----------------------------
func does_stack_match_recipe(stack: Array, recipe: Dictionary) -> bool:
	var inputs: Array = recipe.get("inputs", [])
	if stack.size() != inputs.size():
		return false
	for i in range(inputs.size()):
		if stack[i].subtype != inputs[i].subtype:
			return false
	return true

func is_stack_job_active(stack: Array) -> bool:
	for job in active_jobs:
		if job.get("stack") == stack:
			return true
	return false

# -----------------------------
# Start / Cancel Jobs
# -----------------------------
func start_job(stack: Array, recipe: Dictionary) -> void:
	var job := {
		"stack": stack,
		"recipe": recipe,
		"progress": 0.0,
		"work_time": recipe.get("work_time", 5.0)
	}
	job["progress_bar"] = create_progress_bar(stack)
	active_jobs.append(job)
	print("▶ Job started. Stack:", stack_to_names(stack), "Recipe:", recipe.get("name"))

func cancel_job(job: Dictionary) -> void:
	remove_progress_bar(job)
	print("⏹ Job canceled. Stack:", stack_to_names(job.get("stack", [])), "Recipe:", job.get("recipe", {}).get("name"))
	if active_jobs.has(job):
		active_jobs.erase(job)

func stack_to_names(stack: Array) -> Array:
	var names: Array = []
	for c in stack:
		if is_instance_valid(c):
			names.append(c.subtype)
	return names

# -----------------------------
# Job Updates
# -----------------------------
func update_jobs(delta: float) -> void:
	for job in active_jobs.duplicate():
		if not is_job_still_valid(job):
			cancel_job(job)
			continue
		job["progress"] += delta
		if job.has("progress_bar"):
			update_job_progress_bar(job)
		if job["progress"] >= job["work_time"]:
			complete_job(job)

func complete_job(job: Dictionary) -> void:
	var stack: Array = job["stack"]
	var recipe: Dictionary = job["recipe"]
	print("✅ Job complete! Recipe:", recipe.get("name"), "Stack:", stack_to_names(stack))
	# --- 1) Consume inputs ---
	var inputs: Array = recipe.get("inputs", [])
	for i in range(inputs.size() - 1, -1, -1):
		var c = stack[i] if i < stack.size() else null
		if c and is_instance_valid(c) and inputs[i].get("consume", true):
			# Remove from dragged stack if needed
			if card_manager:
				for j in range(card_manager.dragged_substack.size() - 1, -1, -1):
					if card_manager.dragged_substack[j] == c:
						card_manager.dragged_substack.remove_at(j)
			stack.remove_at(i)
			c.queue_free()
	# --- 2) Fix drag state ---
	if card_manager:
		# Only update drag if the player is dragging a card from this stack
		var is_dragging_this_stack := false
		for c in stack:
			if card_manager.dragged_substack.has(c):
				is_dragging_this_stack = true
				break
		if is_dragging_this_stack:
			var new_dragged_substack: Array = []
			for c in card_manager.dragged_substack:
				if is_instance_valid(c) and stack.has(c):
					new_dragged_substack.append(c)
			card_manager.dragged_substack = new_dragged_substack
			if new_dragged_substack.size() > 0:
				var new_bottom = new_dragged_substack[0]
				card_manager.card_being_dragged = new_bottom
				card_manager.drag_offset = new_bottom.position - card_manager.get_global_mouse_position()
				for k in range(new_dragged_substack.size()):
					var c = new_dragged_substack[k]
					if is_instance_valid(c):
						c.is_being_dragged = true
						c.z_index = int(card_manager.DRAG_Z_INDEX) + k
			else:
				card_manager.card_being_dragged = null
	# --- 3) Produce outputs ---
	if recipe.has("outputs"):
		spawn_outputs(stack, recipe["outputs"])
	elif recipe.has("loot_table"):
		spawn_loot_table_outputs(stack, recipe["loot_table"])
	# --- 4) Cleanup ---
	remove_progress_bar(job)
	active_jobs.erase(job)
	check_all_stacks()

func spawn_card_with_popout(stack: Array, subtype: String) -> void:
	if stack.size() == 0:
		return
	var origin = stack[0].global_position
	var new_card = card_manager.spawn_card(subtype, origin)
	stack.append(new_card)
	# Random direction + distance
	var angle = randf() * TAU
	var distance = randf_range(OUTPUT_MIN_DIST, OUTPUT_MAX_DIST)
	var target_pos = origin + Vector2(cos(angle), sin(angle)) * distance
	# Tween the card from origin to target position
	var tween = get_tree().create_tween()
	tween.tween_property(new_card, "position", target_pos, OUTPUT_TWEEN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Cleanup tween reference when finished
	tween.tween_callback(Callable(self, "_on_card_tween_finished").bind(new_card))
	card_manager.card_tweens[new_card] = tween
	print("Produced output:", new_card.subtype, "on stack (popped out)")

func spawn_outputs(stack: Array, outputs: Array) -> void:
	for out in outputs:
		spawn_card_with_popout(stack, out["subtype"])

func spawn_loot_table_outputs(stack: Array, loot_table: Array) -> void:
	var total_weight = 0
	for entry in loot_table:
		total_weight += entry.get("weight", 0)
	var roll = randf() * total_weight
	for entry in loot_table:
		roll -= entry.get("weight", 0)
		if roll <= 0:
			for out in entry.get("outputs", []):
				spawn_card_with_popout(stack, out["subtype"])
			break

func on_card_tween_finished(card: Node2D) -> void:
	if is_instance_valid(card):
		card_manager.card_tweens.erase(card)

# -----------------------------
# Progress bar
# -----------------------------
func create_progress_bar(stack: Array) -> Control:
	var bar_bg = ColorRect.new()
	bar_bg.color = Color.WHITE
	bar_bg.size = PROGRESS_BAR_SIZE
	bar_bg.name = "JobProgressBar"
	var fill = ColorRect.new()
	fill.name = "Fill"
	fill.color = Color.BLACK
	fill.size = Vector2(0, PROGRESS_BAR_SIZE.y)
	fill.position = Vector2.ZERO
	bar_bg.add_child(fill)
	get_tree().current_scene.add_child(bar_bg)
	update_progress_bar_position(bar_bg, stack)
	return bar_bg

func update_progress_bar_position(bar: Control, stack: Array) -> void:
	if stack.size() > 0 and is_instance_valid(stack[0]):
		bar.global_position = stack[0].global_position + PROGRESS_BAR_OFFSET

func update_job_progress_bar(job: Dictionary) -> void:
	if not job.has("progress_bar") or not is_instance_valid(job["progress_bar"]):
		return
	var bar: ColorRect = job["progress_bar"]
	var fill: ColorRect = bar.get_node("Fill")
	var ratio = clamp(job["progress"] / job["work_time"], 0, 1)
	fill.size.x = PROGRESS_BAR_SIZE.x * ratio
	bar.size = PROGRESS_BAR_SIZE
	update_progress_bar_position(bar, job["stack"])

func remove_progress_bar(job: Dictionary) -> void:
	if job == null:
		return
	if job.has("progress_bar") and is_instance_valid(job["progress_bar"]):
		job["progress_bar"].queue_free()
	if job.has("progress_bar"):
		job.erase("progress_bar")
