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
	# Automatically close inventory if the card enters battle
	if parent_card and parent_card.in_battle and equipment_slots.visible:
		equipment_slots.visible = false

func _on_equipment_button_pressed() -> void:
	if not parent_card:
		return
	if parent_card.in_battle:
		return
	equipment_slots.visible = not equipment_slots.visible
