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

# --- Check if enough money to spawn pack ---
func check_unlock() -> void:
	var spawned_pack := false
	while current_value >= pack_cost and pack_subtype != "":
		spawn_card_pack()
		current_value -= pack_cost
		update_label()
		spawned_pack = true
	if spawned_pack and SoundManager:
		SoundManager.play("card_pop", -4.0)

# --- Spawn the card pack ---
func spawn_card_pack() -> void:
	var card_manager = get_tree().root.get_node("Main/CardManager")
	if not card_manager:
		return
	var pack_card = card_manager.spawn_card(pack_subtype, global_position + Vector2(0, 100))
