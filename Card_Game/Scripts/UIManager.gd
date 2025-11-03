extends CanvasLayer

# --- UI References ---
@onready var card_zoom_panel: Panel = $CardZoomPanel
@onready var card_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/CardZoom
@onready var sprite_zoom: TextureRect = $CardZoomPanel/CardZoomContainer/SpriteZoom
@onready var animated_sprite_zoom: AnimatedSprite2D = $CardZoomPanel/CardZoomContainer/AnimatedSpriteZoom
@onready var card_zoom_label: Label = $CardZoomPanel/CardZoomContainer/CardZoomLabel
@onready var stats_panel: Panel = $StatsPanel
@onready var stats_vbox_container: VBoxContainer = $StatsPanel/StatsVBoxContainer
@onready var pause_menu_panel: Panel = $PauseMenuPanel
@onready var next_day_button: TextureButton = $TimeBarPanel/NextDayButton
@onready var options_panel: Panel = $OptionsPanel
@onready var audio_panel: Panel = $OptionsPanel/AudioPanel
@onready var graphics_panel: Panel = $OptionsPanel/GraphicsPanel

var current_card: Node = null

func _ready() -> void:
	card_zoom_panel.hide()
	stats_panel.hide()
	pause_menu_panel.hide()
	options_panel.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var card_manager = get_node("/root/Main/CardManager")
		var card = card_manager.raycast_check_for_card()
		if card == null or card is InventorySlot or card is SellSlot or card is PackSlot:
			return
		if card:
			open_card_ui(card)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == Key.KEY_ESCAPE and not options_panel.visible:
		toggle_pause_menu()

func open_card_ui(card: Node) -> void:
	if not is_instance_valid(card):
		print("Card is invalid!")
		return
	# Show panels
	card_zoom_panel.show()
	stats_panel.show()
	card_zoom.show()
	card_zoom_label.show()
	# Set textures
	card_zoom.texture = card.card_image.texture
	card_zoom_label.text = card.display_name
	# --- Handle sprite vs animated ---
	if card.sprite_animated and card.sprite_animated.visible and card.sprite_animated.sprite_frames:
		# Use animated sprite
		sprite_zoom.hide()
		animated_sprite_zoom.show()
		animated_sprite_zoom.sprite_frames = card.sprite_animated.sprite_frames
		if animated_sprite_zoom.sprite_frames.has_animation("idle"):
			animated_sprite_zoom.play("idle")
	else:
		# Use static sprite
		animated_sprite_zoom.hide()
		sprite_zoom.show()
		if card.sprite_image and card.sprite_image.texture:
			sprite_zoom.texture = card.sprite_image.texture
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
	if card.value != null:
		var value_label = Label.new()
		value_label.text = "Value: %d" % card.value
		stats_vbox_container.add_child(value_label)
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

func toggle_pause_menu() -> void:
	if pause_menu_panel.visible:
		hide_pause_menu()
		GameSpeedManager.set_speed(GameSpeedManager.prev_speed)  # Resume
	else:
		show_pause_menu()
		GameSpeedManager.set_speed(0.0)  # Pause

func show_pause_menu() -> void:
	pause_menu_panel.show()

func hide_pause_menu() -> void:
	pause_menu_panel.hide()
