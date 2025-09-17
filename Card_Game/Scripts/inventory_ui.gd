extends CanvasLayer
class_name InventoryPanel

# --- UI References ---
@onready var panel_container: Panel = $PanelContainer
@onready var equipment_grid: GridContainer = $PanelContainer/InventoryGrid
@onready var slot_template: TextureButton = $PanelContainer/InventoryGrid/SlotTemplate
@onready var card_zoom_card: TextureRect = $PanelContainer/HBoxContainer/VBoxContainer/CardZoomCard
@onready var card_zoom_sprite: TextureRect = $PanelContainer/HBoxContainer/VBoxContainer/CardZoomSprite
@onready var stats_panel: VBoxContainer = $PanelContainer/HBoxContainer/CardStats

# --- State ---
var current_card: Card = null
var is_open: bool = false
var drag_data: Card = null
var double_click_timer: float = 0.0
const DOUBLE_CLICK_THRESHOLD := 0.25

func _ready() -> void:
	slot_template.visible = false
	hide()

# --- Open / Close Inventory ---
func open_inventory(unit_card: Card) -> void:
	if not unit_card:
		return
	current_card = unit_card
	populate_slots()
	update_card_zoom(unit_card)
	update_stats_panel(unit_card)
	show()
	is_open = true

func close_inventory() -> void:
	clear_slots()
	current_card = null
	hide()
	is_open = false
	drag_data = null

func _process(delta: float) -> void:
	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close_inventory()
	if current_card and current_card.in_battle:
		close_inventory()
	# double-click timer
	if double_click_timer > 0:
		double_click_timer -= delta

# --- Populate / Clear Slots ---
func populate_slots() -> void:
	clear_slots()
	if not current_card or not current_card.equipment_slots:
		return
	for slot_name in current_card.equipment_slots:
		var slot_instance = slot_template.duplicate() as TextureButton
		slot_instance.visible = true
		slot_instance.name = slot_name
		slot_instance.texture_normal = get_empty_texture_for_slot(slot_name)
		slot_instance.connect("gui_input", Callable(self, "_on_slot_gui_input").bind(slot_name))
		equipment_grid.add_child(slot_instance)

func clear_slots() -> void:
	for child in equipment_grid.get_children():
		if child != slot_template:
			child.queue_free()

# --- Slot Interaction ---
func _on_slot_gui_input(event: InputEvent, slot_name: String) -> void:
	if not current_card:
		return
	var slot_card: Card = current_card.equipment.get(slot_name) if current_card.equipment.has(slot_name) else null
	if event is InputEventMouseButton:
		# Left click
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if double_click_timer > 0:
				# Double click → auto equip
				if slot_card:
					equip_card(slot_card, slot_name)
				double_click_timer = 0
			else:
				double_click_timer = DOUBLE_CLICK_THRESHOLD
				if slot_card:
					drag_data = slot_card
		# Right click → unequip
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if slot_card:
				unequip_card(slot_name)

# --- Equip / Unequip Logic ---
func equip_card(card: Card, slot_name: String) -> void:
	if not current_card or not card:
		return
	current_card.equipment[slot_name] = card
	print("Equipped", card.subtype, "to", slot_name)
	populate_slots()

func unequip_card(slot_name: String) -> void:
	if not current_card:
		return
	if current_card.equipment.has(slot_name):
		var card = current_card.equipment[slot_name]
		current_card.equipment[slot_name] = null
		print("Unequipped", card.subtype, "from", slot_name)
		populate_slots()

# --- UI Updates ---
func update_card_zoom(card: Card) -> void:
	if card_zoom_card:
		card_zoom_card.texture = card.card_image.texture
		card_zoom_card.visible = true
	if card_zoom_sprite:
		card_zoom_sprite.texture = card.sprite_image.texture
		card_zoom_sprite.visible = true

func update_stats_panel(card: Card) -> void:
	stats_panel.clear()
	var labels = [
		"Name: %s" % card.subtype,
		"Type: %s" % card.card_type,
		"Health: %d/%d" % [card.health, card.max_health],
		"Attack: %d" % card.attack,
		"Armor: %d" % card.armor
	]
	for text in labels:
		var lbl = Label.new()
		lbl.text = text
		stats_panel.add_child(lbl)

# --- Helpers ---
func get_empty_texture_for_slot(slot_name: String) -> Texture2D:
	# Return default texture for a slot based on its name
	match slot_name:
		"weapon":
			return preload("res://Images/slot_weapon.png")
		"helmet":
			return preload("res://Images/slot_helmet.png")
		"chestplate":
			return preload("res://Images/slot_chestplate.png")
		"leggings":
			return preload("res://Images/slot_leggings.png")
		"boots":
			return preload("res://Images/slot_boots.png")
		"shield":
			return preload("res://Images/slot_shield.png")
		"accessory1":
			return preload("res://Images/slot_accessory.png")
		"accessory2":
			return preload("res://Images/slot_accessory.png")
		"accessory3":
			return preload("res://Images/slot_accessory.png")
		"accessory4":
			return preload("res://Images/slot_accessory.png")
		_:
			return preload("res://Images/slot_default.png")  # fallback for unknown slots
