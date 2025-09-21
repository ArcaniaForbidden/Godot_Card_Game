extends Node2D
class_name PeasantEquipment

@onready var equipment_button: TextureButton = $EquipmentButton
@onready var slots_container: Node2D = $EquipmentSlots

var parent_card: Card

func _ready() -> void:
	parent_card = get_parent() as Card
	slots_container.visible = false
	equipment_button.connect("pressed", Callable(self, "_on_equipment_button_pressed"))
	for slot in slots_container.get_children():
		if slot is EquipmentSlot:
			slot.setup(parent_card)

# Toggle slots visibility
func _on_equipment_button_pressed() -> void:
	if not parent_card or parent_card.in_battle:
		return
	slots_container.visible = not slots_container.visible

# Equip cards to empty slots in order
func equip_cards(cards: Array) -> void:
	for card in cards:
		for slot in slots_container.get_children():
			if slot is EquipmentSlot and slot.can_accept(card):
				slot.equip(card)
				break   # Move to next card

# Unequip a specific card (search for it in slots)
func unequip_card(card: Card) -> void:
	for slot in slots_container.get_children():
		if slot is EquipmentSlot and slot.equipped_card == card:
			slot.unequip()
			break
