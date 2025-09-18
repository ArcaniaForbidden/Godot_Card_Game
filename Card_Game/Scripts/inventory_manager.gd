extends CanvasLayer
class_name InventoryManager

# --- UI References ---
@onready var card_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/CardZoom
@onready var sprite_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/SpriteZoom
@onready var card_zoom_label: Label = $CardZoomPanel/CardZoomContainer/CardZoomLabel
@onready var stats_panel: VBoxContainer = $StatsPanelPanel/StatsPanel

# Equipped slots
@onready var slot_weapon: TextureButton = $EquippedSlotsPanel/SlotWeapon
@onready var slot_helmet: TextureButton = $EquippedSlotsPanel/SlotHelmet
@onready var slot_chestplate: TextureButton = $EquippedSlotsPanel/SlotChestplate
@onready var slot_leggings: TextureButton = $EquippedSlotsPanel/SlotLeggings
@onready var slot_boots: TextureButton = $EquippedSlotsPanel/SlotBoots
@onready var slot_shield: TextureButton = $EquippedSlotsPanel/SlotShield
@onready var slot_accessory1: TextureButton = $EquippedSlotsPanel/SlotAccessory1
@onready var slot_accessory2: TextureButton = $EquippedSlotsPanel/SlotAccessory2
@onready var slot_accessory3: TextureButton = $EquippedSlotsPanel/SlotAccessory3
@onready var slot_accessory4: TextureButton = $EquippedSlotsPanel/SlotAccessory4

# Inventory grid
@onready var inventory_grid: GridContainer = $InventoryPanel/InventoryGrid
@onready var inventory_slot_template: TextureButton = $InventoryPanel/InventoryGrid/InventorySlotTemplate

var current_card: Node = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var card = get_node("/root/Main/CardManager").raycast_check_for_card()
			if card:
				open_card_ui(card)

func open_card_ui(card: Node2D) -> void:
	if not is_instance_valid(card):
		print("Card is invalid!")
		return
	print("Right-clicked card:", card.subtype)
	var card_data = CardDatabase.card_database.get(card.subtype, null)
	if card_data == null:
		print("Card data not found in CardDatabase for subtype:", card.subtype)
		return
	print("Found card data:", card_data)
	# Show zoom and label
	card_zoom.visible = true
	sprite_zoom.visible = true
	card_zoom_label.visible = true
	# Set textures and label
	card_zoom.texture = card_data.get("card", null)
	sprite_zoom.texture = card_data.get("sprite", null)
	card_zoom_label.text = card_data.get("display_name", "Unknown")
	print("UI updated successfully")
