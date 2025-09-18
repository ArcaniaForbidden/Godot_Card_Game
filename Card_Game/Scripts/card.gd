extends Node2D
class_name Card

signal hovered
signal hovered_off
signal inventory_open_requested(card: Card)

const LABEL_COLOR := Color.BLACK

var target_position: Vector2
var is_being_dragged: bool = false
var stack_target_position: Vector2 = Vector2.ZERO
var card_type: String = ""
var subtype: String = ""
var display_name: String = ""
var health: int = 0
var max_health: int = 0
var attack: int = 0
var armor: int = 0
var attack_speed: float = 1.0          # default attacks per second
var enemy_idle_timer: float = 0.0
var enemy_min_jump_time: float = 0.8
var enemy_max_jump_time: float = 1.5
var enemy_jump_distance: float = 150.0
var in_battle: bool = false
var inventory: Array = []
var equipment_slots: Array = []
var equipment: Dictionary = {}

# UI references
@onready var display_name_label: Label = get_node_or_null("CardLabel")
@onready var card_image: Sprite2D = get_node_or_null("CardImage")
@onready var sprite_image: Sprite2D = get_node_or_null("SpriteImage")
@onready var health_icon: Node2D = get_node_or_null("HealthIcon")
@onready var health_label: Label = get_node_or_null("HealthLabel")
@onready var area: Area2D = $Area2D

func _ready() -> void:
	# Connect input_event signal of Area2D to this card
	area.connect("input_event", Callable(self, "_on_area_input_event"))

# --- Add an item to this card's inventory ---
func add_to_inventory(item_card: Card) -> void:
	if item_card in inventory:
		return
	inventory.append(item_card)

# --- Remove an item from this card's inventory ---
func remove_from_inventory(item_card: Card) -> void:
	if item_card in inventory:
		inventory.erase(item_card)

# --- Helper for health ---
func set_health(value: int) -> void:
	health = value
	if health_label:
		health_label.text = str(health)
		health_label.self_modulate = LABEL_COLOR
	if health_icon:
		health_icon.visible = true

# --- Setup function ---
func setup(subtype_name: String) -> void:
	subtype = subtype_name
	target_position = position 
	var data = CardDatabase.card_database[subtype]
	card_type = data.get("card_type", "")
	display_name = data.get("display_name", subtype)
	if card_image and data.has("card"):
		card_image.texture = data["card"]
	if sprite_image and data.has("sprite"):
		sprite_image.texture = data["sprite"]
	if display_name_label:
		display_name_label.horizontal_alignment = 1
		display_name_label.vertical_alignment = 1
		display_name_label.text = display_name
		display_name_label.self_modulate = LABEL_COLOR
	if card_type == "unit" and data.has("equipment_slots"):
		equipment_slots = data["equipment_slots"]
		for slot_name in equipment_slots:
			equipment[slot_name] = null
	# Health setup
	if data.has("health"):
		max_health = int(data["health"])
		set_health(max_health)
	else:
		if health_icon:
			health_icon.visible = false
		if health_label:
			health_label.text = ""
			health_label.visible = false
	# Store internal stats for logic (not shown in UI)
	attack = int(data.get("attack", 0))
	armor = int(data.get("armor", 0))
	attack_speed = float(data.get("attack_speed", 1.0))

# --- Hover signals ---
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

func _on_area_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("inventory_open_requested", self)
