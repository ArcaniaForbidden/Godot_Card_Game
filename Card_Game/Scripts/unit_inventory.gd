extends Control
class_name UnitInventory

# The card this inventory belongs to
var unit_card: Card = null

# List of slot buttons
@export var slots: Array[TextureButton] = []

# Default empty slot texture
@export var empty_slot_texture: Texture

func _ready() -> void:
	hide()  # Hide inventory initially

func set_unit_card(card: Card) -> void:
	unit_card = card
	# Position the inventory just below the card
	global_position = card.global_position + Vector2(0, card.card_image.texture.get_size().y / 2 + 20)
	show()

# Update the slot visuals based on equipped items
func update_slots() -> void:
	if not unit_card:
		return
	for slot_button in slots:
		if unit_card.equipment.has(slot_button.slot_type):
			var equipped_card = unit_card.equipment[slot_button.slot_type]
			slot_button.texture_normal = equipped_card.sprite_image.texture
		else:
			slot_button.texture_normal = empty_slot_texture
