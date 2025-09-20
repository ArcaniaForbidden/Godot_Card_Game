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
		if card:
			open_card_ui(card)
		
func open_card_ui(card: Node) -> void:
	if not is_instance_valid(card):
		print("Card is invalid!")
		return
	# Show the panels
	card_zoom_panel.show()
	stats_panel.show()
	card_zoom.show()
	sprite_zoom.show()
	card_zoom_label.show()
	# Set the textures
	card_zoom.texture = card.card_image.texture
	sprite_zoom.texture = card.sprite_image.texture
	card_zoom_label.text = card.display_name
	# --- Clear previous stats ---
	for child in stats_vbox_container.get_children():
		child.queue_free()
	# Type label
	var type_label = Label.new()
	type_label.text = "Type: %s" % card.card_type.capitalize()
	stats_vbox_container.add_child(type_label)
	# Display stats
	for stat_name in card.stats.keys():
		var stat_value = card.stats[stat_name]
		if typeof(stat_value) == TYPE_DICTIONARY:
			for sub_stat in stat_value.keys():
				var label = Label.new()
				label.text = "%s %s%s" % [
					sub_stat.capitalize(),
					"+" if stat_name == "add" else "x",
					str(stat_value[sub_stat])
				]
				stats_vbox_container.add_child(label)
		else:
			var label = Label.new()
			label.text = "%s: %s" % [stat_name.capitalize(), str(stat_value)]
			stats_vbox_container.add_child(label)
