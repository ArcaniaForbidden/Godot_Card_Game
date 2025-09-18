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
@onready var equipment_slots_panel: Panel = $EquipmentSlotsPanel
@onready var slot_weapon: TextureButton = $EquipmentSlotsPanel/SlotWeapon
@onready var slot_helmet: TextureButton = $EquipmentSlotsPanel/SlotHelmet
@onready var slot_chestplate: TextureButton = $EquipmentSlotsPanel/SlotChestplate
@onready var slot_leggings: TextureButton = $EquipmentSlotsPanel/SlotLeggings
@onready var slot_boots: TextureButton = $EquipmentSlotsPanel/SlotBoots
@onready var slot_shield: TextureButton = $EquipmentSlotsPanel/SlotShield
@onready var slot_accessory1: TextureButton = $EquipmentSlotsPanel/SlotAccessory1
@onready var slot_accessory2: TextureButton = $EquipmentSlotsPanel/SlotAccessory2
@onready var slot_accessory3: TextureButton = $EquipmentSlotsPanel/SlotAccessory3
@onready var slot_accessory4: TextureButton = $EquipmentSlotsPanel/SlotAccessory4

# Inventory grid
@onready var inventory_panel: Panel = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/InventoryGrid
@onready var inventory_slot_template: TextureButton = $InventoryPanel/InventoryGrid/InventorySlotTemplate

var current_card: Node = null

func _ready() -> void:
	equipment_slots_panel.hide()
	inventory_panel.hide()
	card_zoom_panel.hide()
	stats_panel_panel.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var card_manager = get_node("/root/Main/CardManager")
		var card = card_manager.raycast_check_for_card()
		if card:
			open_card_ui(card)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# Close inventory and equipment panels
			if inventory_panel.visible:
				inventory_panel.hide()
			if equipment_slots_panel.visible:
				equipment_slots_panel.hide()
		
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
		equipment_slots_panel.show()
		populate_inventory(card)
		populate_equipment_slots(card)
	else:
		inventory_panel.hide()
		equipment_slots_panel.hide()

func clear_inventory_and_equipment() -> void:
	# Clear inventory grid
	for child in inventory_grid.get_children():
		if child != inventory_slot_template:  # Keep the template
			child.queue_free()
	# Clear equipped slots
	for slot_name in ["slot_weapon","slot_helmet","slot_chestplate","slot_leggings",
					  "slot_boots","slot_shield","slot_accessory1","slot_accessory2",
					  "slot_accessory3","slot_accessory4"]:
		var slot = get_node("EquippedSlotsPanel/" + slot_name) as TextureButton
		if slot:
			slot.texture = null
			slot.disabled = true  # optional, disables empty slots

func populate_equipment_slots(card: Card) -> void:
	if not is_instance_valid(card):
		return
	# Map slot names to their corresponding nodes
	var slot_nodes := {
		"weapon": $EquipmentSlotsPanel/SlotWeapon,
		"helmet": $EquipmentSlotsPanel/SlotHelmet,
		"chestplate": $EquipmentSlotsPanel/SlotChestplate,
		"leggings": $EquipmentSlotsPanel/SlotLeggings,
		"boots": $EquipmentSlotsPanel/SlotBoots,
		"shield": $EquipmentSlotsPanel/SlotShield,
		"accessory1": $EquipmentSlotsPanel/SlotAccessory1,
		"accessory2": $EquipmentSlotsPanel/SlotAccessory2,
		"accessory3": $EquipmentSlotsPanel/SlotAccessory3,
		"accessory4": $EquipmentSlotsPanel/SlotAccessory4
	}
	for slot_name in slot_nodes.keys():
		var slot = slot_nodes[slot_name]
		if not slot:
			continue
		# Get child nodes
		var card_tex = slot.get_node_or_null("CardTexture") as TextureRect
		var sprite_tex = slot.get_node_or_null("SpriteTexture") as TextureRect
		var label = slot.get_node_or_null("CardLabel") as Label
		var equipped_card = card.equipment.get(slot_name, null)
		if equipped_card:
			# Show equipped item
			if card_tex:
				card_tex.texture = equipped_card.card_image.texture
				card_tex.show()
			if sprite_tex:
				sprite_tex.texture = equipped_card.sprite_image.texture
				sprite_tex.show()
			if label:
				label.text = equipped_card.display_name
				label.show()
		else:
			# No item → hide children, keep placeholder visible
			if card_tex:
				card_tex.texture = null
				card_tex.hide()
			if sprite_tex:
				sprite_tex.texture = null
				sprite_tex.hide()
			if label:
				label.text = ""
				label.hide()

func populate_inventory(card: Node) -> void:
	# First, clear any previous inventory slots except the template
	for child in inventory_grid.get_children():
		if child != inventory_slot_template:
			child.queue_free()
	# Loop through each item in the card's inventory
	for item_card in card.inventory:
		var slot_instance = inventory_slot_template.duplicate()
		slot_instance.visible = true
		slot_instance.disabled = false
		# Set textures and label
		var card_texture = slot_instance.get_node("CardTexture") as TextureRect
		var sprite_texture = slot_instance.get_node("SpriteTexture") as TextureRect
		var card_label = slot_instance.get_node("CardLabel") as Label
		if card_texture:
			card_texture.texture = item_card.card_image.texture
		if sprite_texture:
			sprite_texture.texture = item_card.sprite_image.texture
		if card_label:
			card_label.text = item_card.display_name
		inventory_grid.add_child(slot_instance)
