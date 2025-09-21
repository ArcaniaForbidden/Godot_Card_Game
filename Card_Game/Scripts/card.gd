extends Node2D
class_name Card

signal hovered
signal hovered_off
signal ui_zoom_update(card: Card)

const LABEL_COLOR := Color.BLACK

var target_position: Vector2
var is_being_dragged: bool = false
var stack_target_position: Vector2 = Vector2.ZERO
var card_type: String = ""
var subtype: String = ""
var display_name: String = ""
var slot: String = ""
var stats: Dictionary = {}
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

# --- UI references ---
@onready var display_name_label: Label = get_node_or_null("CardLabel")
@onready var card_image: Sprite2D = get_node_or_null("CardImage")
@onready var sprite_image: Sprite2D = get_node_or_null("SpriteImage")
@onready var health_icon: Node2D = get_node_or_null("HealthIcon")
@onready var health_label: Label = get_node_or_null("HealthLabel")
@onready var area: Area2D = get_node_or_null("Area2D")

func _ready() -> void:
	area.connect("input_event", Callable(self, "_on_area_input_event"))

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
	# Set textures
	if card_image and data.has("card"):
		card_image.texture = data["card"]
	if sprite_image and data.has("sprite"):
		sprite_image.texture = data["sprite"]
	if display_name_label:
		display_name_label.horizontal_alignment = 1
		display_name_label.vertical_alignment = 1
		display_name_label.text = display_name
		display_name_label.self_modulate = LABEL_COLOR
	if card_type == "equipment":
		slot = data.get("slot", "")
	else:
		slot = ""
	# --- Stats setup ---
	stats = data.get("stats", {}).duplicate(true)
	if stats.has("health") and stats["health"] > 0:
		max_health = int(stats["health"])
		set_health(max_health)
	else:
		max_health = 0
		health = 0
		if health_icon:
			health_icon.visible = false
		if health_label:
			health_label.text = ""
			health_label.visible = false
	attack = int(stats.get("attack", 0))
	armor = int(stats.get("armor", 0))
	attack_speed = float(stats.get("attack_speed", 1.0))
	if subtype == "peasant" and not has_node("PeasantEquipment"):
		var peasant_equipment_scene = preload("res://Scenes/PeasantEquipment.tscn")
		var equipment_instance = peasant_equipment_scene.instantiate()
		add_child(equipment_instance)
		equipment_instance.parent_card = self
		equipment_instance.position = Vector2(0, 80)
		equipment_instance.get_node("EquipmentButton").visible = true

# --- Hover signals ---
func _on_area_input_event(viewport: Object, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("ui_zoom_update", self)
