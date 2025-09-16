extends Node2D
class_name Card

signal hovered
signal hovered_off

const LABEL_COLOR := Color.BLACK

var target_position: Vector2
var is_being_dragged: bool = false
var stack_target_position: Vector2 = Vector2.ZERO
var card_type: String = ""
var subtype: String = ""
var health: int = 0
var attack: int = 0
var armor: int = 0
var attack_speed: float = 1.0  # default attacks per second
var in_battle: bool = false

# UI references
@onready var display_name_label: Label = get_node_or_null("CardLabel")
@onready var card_image: Sprite2D = get_node_or_null("CardImage")
@onready var icon_nodes: Dictionary[String, Node2D] = {
	"health": get_node_or_null("HealthIcon"),
	"attack": get_node_or_null("AttackIcon"),
	"armor": get_node_or_null("ArmorIcon")
}
@onready var label_nodes: Dictionary[String, Label] = {
	"health": get_node_or_null("HealthIcon/HealthLabel"),
	"attack": get_node_or_null("AttackIcon/AttackLabel"),
	"armor": get_node_or_null("ArmorIcon/ArmorLabel")
}

# --- Centralized helper for stats ---
func set_stat(stat_name: String, value: int) -> void:
	self.set(stat_name, value)  # updates health/attack/armor
	if label_nodes[stat_name]:
		label_nodes[stat_name].text = str(value)
		label_nodes[stat_name].self_modulate = LABEL_COLOR
	if icon_nodes[stat_name]:
		icon_nodes[stat_name].visible = true

# --- Centralized setup function ---
func setup(subtype_name: String) -> void:
	subtype = subtype_name
	target_position = position 
	var data = CardDatabase.card_database[subtype]
	# Set card type
	card_type = data.get("card_type", "")
	# Set sprite
	if card_image and data.has("sprite"):
		card_image.texture = data["sprite"]
	# Set display name
	if display_name_label:
		display_name_label.horizontal_alignment = 1
		display_name_label.vertical_alignment = 1
		display_name_label.text = data.get("display_name", subtype)
		display_name_label.self_modulate = LABEL_COLOR
	# --- Stats driven directly by DB ---
	for stat_name in ["health", "attack", "armor"]:
		if data.has(stat_name):
			set_stat(stat_name, int(data[stat_name]))
		else:
			if icon_nodes.has(stat_name) and icon_nodes[stat_name]:
				icon_nodes[stat_name].visible = false
	# attack_speed handled separately (no UI needed)
	if data.has("attack_speed"):
		attack_speed = float(data["attack_speed"])

# --- Hover signals ---
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)
	print("hovered")

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
	print("hovered off")
