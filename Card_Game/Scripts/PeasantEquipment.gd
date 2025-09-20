extends Node2D

@onready var inventory_button: TextureButton = $EquipmentButton
@onready var equipment_slots: Node2D = $EquipmentSlots
@onready var weapon_slot: Node2D = $EquipmentSlots/WeaponSlot
@onready var helmet_slot: Node2D = $EquipmentSlots/HelmetSlot
@onready var chestplate_slot: Node2D = $EquipmentSlots/ChestplateSlot
@onready var leggings_slot: Node2D = $EquipmentSlots/LeggingsSlot
@onready var boots_slot: Node2D = $EquipmentSlots/BootsSlot

var parent_card: Card

func _ready() -> void:
	parent_card = get_parent() as Card
	equipment_slots.visible = false
	inventory_button.connect("pressed", Callable(self, "_on_equipment_button_pressed"))

func _process(delta: float) -> void:
	if parent_card and parent_card.in_battle and equipment_slots.visible:
		equipment_slots.visible = false

func _on_equipment_button_pressed() -> void:
	if not parent_card or parent_card.in_battle:
		return
	_toggle_equipment_slots(not equipment_slots.visible)

func _toggle_equipment_slots(state: bool) -> void:
	equipment_slots.visible = state
	var state_text := "OPEN" if state else "CLOSED"
	for slot in equipment_slots.get_children():
		if slot is EquipmentSlot:
			slot.active = state
			if slot.has_node("Area2D"):
				slot.get_node("Area2D").monitoring = state
