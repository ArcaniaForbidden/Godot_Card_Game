extends Control
class_name PeasantInventory

@onready var button: TextureButton = $InventoryButton
@onready var container: Control = $InventoryContainer

var slot_cards: Array = []

func _ready():
	container.hide()
	button.pressed.connect(_on_button_pressed)
	slot_cards.clear()
	call_deferred("_register_slots")  # wait until layout is complete

func _register_slots():
	var card_manager = get_tree().root.get_node("Main/CardManager")
	for slot in container.get_children():
		if slot is InventorySlot:
			slot_cards.append(slot)
			if not card_manager.all_stacks.has([slot]):
				card_manager.all_stacks.append([slot])

func _on_button_pressed():
	var card_manager = get_tree().root.get_node("Main/CardManager")
	var hovered_card = card_manager.raycast_check_for_card()
	if hovered_card:
		return  
	var new_visible = !container.visible
	container.visible = new_visible
	for slot in slot_cards:
		slot.visible = new_visible
		if slot.attached_card and is_instance_valid(slot.attached_card):
			slot.attached_card.visible = new_visible
