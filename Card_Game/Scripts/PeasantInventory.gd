extends Control
class_name PeasantInventory

@onready var button: TextureButton = $InventoryButton
@onready var container: Control = $InventoryContainer

var slot_cards: Array = []

func _ready():
	container.hide()
	button.pressed.connect(_on_button_pressed)
	slot_cards.clear()
	for slot in container.get_children():
		if slot is InventorySlot:
			slot_cards.append(slot)
			print("Slot ", slot.name, " set to accept: ", slot.slot_type)
		if slot is Card:
			print(slot.name, " is a Card")
		else:
			print(slot.name, " is NOT a Card")

func _on_button_pressed():
	container.visible = !container.visible
