extends Node2D

signal hovered
signal hovered_off

@export var subtype: String = "villager"  # default subtype

# Internal stat storage
var health: int = 0
var attack: int = 0
var armor: int = 0

# Metadata
var card_type: String = ""

# UI references
@onready var display_name_label: Label = get_node_or_null("CardLabel")
@onready var card_image: Sprite2D = get_node_or_null("CardImage")
@onready var icon_nodes: Dictionary = {
	"health": get_node_or_null("HealthIcon"),
	"attack": get_node_or_null("AttackIcon"),
	"armor": get_node_or_null("ArmorIcon")
}
@onready var label_nodes: Dictionary = {
	"health": get_node_or_null("HealthIcon/HealthLabel"),
	"attack": get_node_or_null("AttackIcon/AttackLabel"),
	"armor": get_node_or_null("ArmorIcon/ArmorLabel")
}

# --- Centralized helper for stats ---
func set_stat(stat_name: String, value: int) -> void:
	self.set(stat_name, value)  # updates health/attack/armor
	if label_nodes[stat_name]:
		label_nodes[stat_name].text = str(value)
		label_nodes[stat_name].self_modulate = Color.BLACK
	if icon_nodes[stat_name]:
		icon_nodes[stat_name].visible = true

# --- Centralized setup function ---
func setup(subtype_name: String) -> void:
	subtype = subtype_name
	var data = CardDatabase.card_database[subtype]
	# Set card type
	card_type = data.get("card_type", "")
	# Set sprite
	if card_image:
		card_image.texture = load(data.get("sprite"))
	# Set display name
	if display_name_label:
		display_name_label.horizontal_alignment = 1
		display_name_label.vertical_alignment = 1
		display_name_label.text = data.get("display_name", subtype)
		display_name_label.self_modulate = Color.BLACK
	# --- Stats driven directly by DB ---
	for stat_name in ["health", "attack", "armor"]:
		if data.has(stat_name):
			set_stat(stat_name, data[stat_name])
		else:
			if icon_nodes[stat_name]:
				icon_nodes[stat_name].visible = false

# --- Hover signals ---
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
