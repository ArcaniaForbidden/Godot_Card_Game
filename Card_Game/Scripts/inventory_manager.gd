extends CanvasLayer
class_name InventoryManager

# --- UI References ---
@onready var card_zoom_panel: Panel = $CardZoomPanel
@onready var card_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/CardZoom
@onready var sprite_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/SpriteZoom
@onready var card_zoom_label: Label = $CardZoomPanel/CardZoomContainer/CardZoomLabel
@onready var stats_panel_panel: Panel = $StatsPanelPanel
@onready var stats_panel: VBoxContainer = $StatsPanelPanel/StatsPanel

# Equipped slots
@onready var equipped_slots_panel: Panel = $EquippedSlotsPanel
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
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/InventoryGrid
@onready var inventory_slot_template: TextureButton = $InventoryPanel/InventoryGrid/InventorySlotTemplate

var current_card: Node = null

func _ready() -> void:
	equipped_slots_panel.hide()
	inventory_panel.hide()
	card_zoom_panel.hide()
	stats_panel_panel.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var card_manager = get_node("/root/Main/CardManager")
		var card = card_manager.raycast_check_for_card()
		if card:
			open_card_ui(card)

func open_card_ui(card: Node) -> void:
	if not is_instance_valid(card):
		print("Card is invalid!")
		return
	# Show the panels
	card_zoom_panel.show()
	stats_panel_panel.show()
	card_zoom.show()
	sprite_zoom.show()
	card_zoom_label.show()
	# Set the textures
	card_zoom.texture = card.card_image.texture
	sprite_zoom.texture = card.sprite_image.texture
	card_zoom_label.text = card.display_name
	# --- Clear previous stats ---
	for child in stats_panel.get_children():
		child.queue_free()
	var type_label = Label.new()
	type_label.text = "Type: %s" % card.card_type.capitalize()
	stats_panel.add_child(type_label)
	# --- Display stats ---
	for stat_name in card.stats.keys():
		var stat_value = card.stats[stat_name]
		if typeof(stat_value) == TYPE_DICTIONARY:
			# For equipment stats like "add" and "mul"
			for sub_stat in stat_value.keys():
				var label = Label.new()
				label.text = "%s %s%s" % [
					sub_stat.capitalize(),
					"+" if stat_name == "add" else "x",
					str(stat_value[sub_stat])
				]
				stats_panel.add_child(label)
		else:
			# Normal stats like health, attack, armor
			var label = Label.new()
			label.text = "%s: %s" % [stat_name.capitalize(), str(stat_value)]
			stats_panel.add_child(label)
	if card.card_type == "unit":
		inventory_panel.show()
		equipped_slots_panel.show()
	else:
		inventory_panel.hide()
		equipped_slots_panel.hide()
