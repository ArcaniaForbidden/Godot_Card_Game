extends CanvasLayer
class_name UIManager

# --- UI References ---
@onready var card_zoom_panel: Panel = $CardZoomPanel
@onready var card_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/CardZoom
@onready var sprite_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/SpriteZoom
@onready var card_zoom_label: Label = $CardZoomPanel/CardZoomContainer/CardZoomLabel
@onready var stats_panel: Panel = $StatsPanel
@onready var stats_vbox_container: VBoxContainer = $StatsPanel/StatsVBoxContainer

var current_card: Node = null

func _ready() -> void:
	card_zoom_panel.hide()
	stats_panel.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var card_manager = get_node("/root/Main/CardManager")
		var card = card_manager.raycast_check_for_card()
		if card == null or card is InventorySlot:
			return
		if card:
			open_card_ui(card)
		
func open_card_ui(card: Node) -> void:
	if not is_instance_valid(card):
		print("Card is invalid!")
		return
	# Show panels
	card_zoom_panel.show()
	stats_panel.show()
	card_zoom.show()
	sprite_zoom.show()
	card_zoom_label.show()
	# Set textures
	card_zoom.texture = card.card_image.texture
	sprite_zoom.texture = card.sprite_image.texture
	card_zoom_label.text = card.display_name
	# Clear previous stats
	# Clear previous stats
	for child in stats_vbox_container.get_children():
		child.queue_free()
	# Type label
	var type_label = Label.new()
	type_label.text = "Type: %s" % card.card_type.capitalize()
	stats_vbox_container.add_child(type_label)
	var stat_properties = {
		"Health": "%d/%d" % [card.health, card.max_health],
		"Attack": card.attack,
		"Armor": card.armor,
		"Attack Speed": card.attack_speed
	}
	# Display stats
	for stat_name in stat_properties.keys():
		var stat_value = stat_properties[stat_name]
		if stat_name == "Health":
			# Always show health
			if card.max_health > 0:
				var label = Label.new()
				label.text = "%s: %s" % [stat_name, str(stat_value)]
				stats_vbox_container.add_child(label)
		elif stat_value != null and stat_value != 0:
			# Only show non-zero stats
			var label = Label.new()
			label.text = "%s: %s" % [stat_name, str(stat_value)]
			stats_vbox_container.add_child(label)
	# Show equipment stat modifiers if this card is equipment
	if card.card_type == "equipment" and card.stats:
		if card.stats.has("add"):
			for key in card.stats["add"].keys():
				var label = Label.new()
				label.text = "%s: +%s" % [key.capitalize(), str(card.stats["add"][key])]
				stats_vbox_container.add_child(label)
		if card.stats.has("mul"):
			for key in card.stats["mul"].keys():
				var label = Label.new()
				label.text = "%s: x%s" % [key.capitalize(), str(card.stats["mul"][key])]
				stats_vbox_container.add_child(label)
