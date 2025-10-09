extends Card
class_name PackSlot

const PACK_TEXTURES := {
	"plains_card_pack": preload("res://Images/pack_slot_plains.png"),
	"forest_card_pack": preload("res://Images/pack_slot_forest.png"),
	"mountain_card_pack": preload("res://Images/pack_slot_mountain.png")
}

# --- Properties ---
var pack_subtype: String = ""   # The type of card pack this slot produces
var pack_cost: int = 0          # Cost in coins to unlock
var current_value: int = 0              # Tracks inserted coins
var packs_to_spawn: int = 0  # tracks packs that still need to be visually spawned
var is_spawning_packs: bool = false

@onready var progress_label: Label = $PackProgressLabel
@onready var slot_sprite: Sprite2D = $PackSlotSprite  # The texture to display

func set_pack_type(subtype: String, cost: int) -> void:
	pack_subtype = subtype
	pack_cost = cost
	update_label()
	update_texture()

func update_texture() -> void:
	if PACK_TEXTURES.has(pack_subtype):
		slot_sprite.texture = PACK_TEXTURES[pack_subtype]

func update_label() -> void:
	progress_label.text = "%d/%d" % [current_value, pack_cost]

# --- Accept coins/cards ---
func add_value(card: Card) -> void:
	if card.card_type != "currency":
		return
	current_value += card.value
	update_label()
	if is_instance_valid(card):
		var stack = get_tree().root.get_node("Main/CardManager").find_stack(card)
		if stack:
			stack.erase(card)
		card.queue_free()
	check_unlock()

func check_unlock() -> void:
	while current_value >= pack_cost:
		current_value -= pack_cost
		packs_to_spawn += 1
		update_label()
	if not is_spawning_packs and packs_to_spawn > 0:
		is_spawning_packs = true
		spawn_card_pack_queue()

func spawn_card_pack_queue() -> void:
	if packs_to_spawn <= 0:
		is_spawning_packs = false
		return
	await spawn_card_pack()  # spawn one pack
	packs_to_spawn -= 1
	# Wait a short time before spawning the next pack
	await get_tree().create_timer(0.5).timeout
	spawn_card_pack_queue()  # recursively spawn the next pack

func spawn_card_pack() -> void:
	var card_manager = get_tree().root.get_node("Main/CardManager")
	if not card_manager:
		return
	# Spawn the pack card itself (will be opened later)
	var spawn_pos = global_position + Vector2(0, -300)
	var final_pos = global_position + Vector2(0, 200)
	var pack_card = card_manager.spawn_card(pack_subtype, spawn_pos)
	if SoundManager:
		SoundManager.play("card_pop", -6.0)
	pack_card.is_being_simulated_dragged = true
	pack_card.z_index = card_manager.DRAG_Z_INDEX
	pack_card.scale = Vector2(1.1, 1.1)
	# --- Position tween ---
	var tween_pos = get_tree().create_tween()
	tween_pos.tween_property(pack_card, "position", final_pos, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# --- Scale tween (pop in mid-flight) ---
	var tween_scale = get_tree().create_tween()
	tween_scale.tween_property(pack_card, "scale", Vector2(1.25, 1.25), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_scale.tween_property(pack_card, "scale", Vector2(1.1, 1.1), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# --- Finish callback ---
	tween_pos.finished.connect(Callable(func() -> void:
		if is_instance_valid(pack_card):
			pack_card.is_being_simulated_dragged = false
			card_manager.finish_drag_simulated([pack_card])
	))
