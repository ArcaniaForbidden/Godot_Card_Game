extends Node2D
class_name Card

signal hovered
signal hovered_off
signal ui_zoom_update(card: Card)

const LABEL_COLOR := Color.BLACK

var target_position: Vector2
var is_being_dragged: bool = false
var is_being_simulated_dragged: bool = false
var card_type: String = ""
var attack_type: String = ""
var subtype: String = ""
var display_name: String = ""
var value = null
var slot: String = ""
var stats: Dictionary = {}
var health: int = 0
var max_health: int = 0
var attack: int = 0
var armor: int = 0
var attack_speed: float = 1.0          # default attacks per second
var enemy_idle_timer: float = 0.0
var enemy_min_jump_time: float = 0.8
var enemy_max_jump_time: float = 1.5
var enemy_jump_distance: float = 150.0
var in_battle: bool = false
var is_equipped: bool = false
var is_equipping: bool = false
var attached_slot: InventorySlot = null
var loot_table: Array = []

# --- UI references ---
@onready var animation_manager: AnimationManager = AnimationManager.new()
@onready var display_name_label: Label = get_node_or_null("CardLabel")
@onready var card_pack_label1: Label = get_node_or_null("CardPackLabel1")
@onready var card_pack_label2: Label = get_node_or_null("CardPackLabel2")
@onready var card_image: Sprite2D = get_node_or_null("CardImage")
@onready var sprite_image: Sprite2D = get_node_or_null("SpriteImage")
@onready var sprite_animated: AnimatedSprite2D = get_node_or_null("SpriteAnimated")
@onready var health_icon: Node2D = get_node_or_null("HealthIcon")
@onready var health_label: Label = get_node_or_null("HealthLabel")
@onready var value_icon: Sprite2D = get_node_or_null("ValueIcon")
@onready var value_label: Label = get_node_or_null("ValueLabel")
@onready var area: Area2D = get_node_or_null("Area2D")
@onready var foil_overlay: Sprite2D = get_node_or_null("FoilOverlay")

func _ready() -> void:
	area.connect("input_event", Callable(self, "_on_area_input_event"))
	if sprite_animated:
		animation_manager.setup(self, sprite_animated)

func _process(delta: float) -> void:
	if foil_overlay and foil_overlay.material:
		var camera = get_viewport().get_camera_2d()
		if camera:
			var screen_pos = global_position - camera.global_position + get_viewport().size * 0.5
			var norm_pos = (screen_pos / Vector2(get_viewport().size)) * 4.0
			foil_overlay.material.set_shader_parameter("screen_pos", norm_pos)

# --- Helpers ---
func set_health(value: int) -> void:
	health = clamp(value, 0, max_health)
	if health_label:
		health_label.text = "%d/%d" % [health, max_health]
		health_label.self_modulate = LABEL_COLOR
	if health_icon:
		health_icon.visible = true

func apply_foil_effect(rarity: String) -> void:
	if not foil_overlay:
		return
	var foil_material := ShaderMaterial.new()
	foil_material.shader = preload("res://Shaders/foil_shader.gdshader")
	match rarity:
		"silver":
			foil_material.set_shader_parameter("foil_color", Color(1,1,1,0.3))
			foil_material.set_shader_parameter("rainbow_mode", false)
		"gold":
			foil_material.set_shader_parameter("foil_color", Color(1,0.84,0,0.3))
			foil_material.set_shader_parameter("rainbow_mode", false)
		"ultra":
			foil_material.set_shader_parameter("rainbow_mode", true)
		_:
			foil_overlay.visible = false
			return
	foil_overlay.material = foil_material
	# --- Only card packs get the zigzag mask ---
	if card_type == "currency":
		foil_overlay.texture = preload("res://Images/foil_mask_coin.png")
	if card_type == "card_pack":
		foil_overlay.texture = preload("res://Images/foil_mask_card_pack.png")
	if subtype.ends_with("_ingot"):
		foil_overlay.texture = preload("res://Images/foil_mask_ingot.png")

func remove_foil_effect() -> void:
	if foil_overlay:
		foil_overlay.visible = false
		foil_overlay.material = null

# --- Setup function ---
func setup(subtype_name: String) -> void:
	subtype = subtype_name
	target_position = position 
	var data = CardDatabase.card_database[subtype]
	card_type = data.get("card_type", "")
	print("Setup card '%s': card_type=%s, slot=%s" % [subtype, card_type, data.get("slot","")])
	display_name = data.get("display_name", subtype)
	# Set textures
	apply_foil_effect(data.get("rarity", ""))
	var is_animated = data.get("animated", false)
	if stats.has("attack_type") or card_type in ["unit", "enemy", "neutral", "building"]:
		attack_type = stats.get("attack_type", "melee")
	else:
		attack_type = ""
	if card_type == "card_pack":
		if card_pack_label1:
			var parts := subtype.split("_")
			var first_word := parts[0].capitalize()
			card_pack_label1.visible = true
			card_pack_label1.text = first_word
			card_pack_label1.horizontal_alignment = 1
			card_pack_label1.vertical_alignment = 1
			card_pack_label1.self_modulate = LABEL_COLOR
		if card_pack_label2:
			card_pack_label2.visible = true
			card_pack_label2.text = "Card Pack"
			card_pack_label2.horizontal_alignment = 1
			card_pack_label2.vertical_alignment = 1
			card_pack_label2.self_modulate = LABEL_COLOR
	else:
		if card_pack_label1:
			card_pack_label1.visible = false
		if card_pack_label2:
			card_pack_label2.visible = false
	if card_image and data.has("card"):
		card_image.texture = data["card"]
	if sprite_image:
		sprite_image.visible = not is_animated
		if not is_animated and data.has("sprite"):
			sprite_image.texture = data["sprite"]
	if sprite_animated:
		sprite_animated.visible = is_animated
		if is_animated and data.has("sprite"):
			sprite_animated.sprite_frames = data["sprite"]
			if sprite_animated.sprite_frames.has_animation("idle"):
				sprite_animated.play("idle")
	if display_name_label:
		display_name_label.horizontal_alignment = 1
		display_name_label.vertical_alignment = 1
		display_name_label.text = display_name
		display_name_label.self_modulate = LABEL_COLOR
	if card_type == "equipment":
		slot = data.get("slot", "")
	else:
		slot = ""
	# --- Set value from card data ---
	if data.has("value"):
		value = int(data["value"])
	else:
		value = null
	# --- Show/hide value label and icon ---
	if value != null:
		if value_icon:
			value_icon.visible = true
		if value_label:
			value_label.visible = true
			value_label.text = str(value)
			value_label.horizontal_alignment = 1
			value_label.vertical_alignment = 1
			value_label.self_modulate = LABEL_COLOR
	else:
		if value_icon:
			value_icon.visible = false
		if value_label:
			value_label.visible = false
	# --- Stats setup ---
	stats = data.get("stats", {}).duplicate(true)
	if stats.has("health") and stats["health"] > 0:
		max_health = int(stats["health"])
		set_health(max_health)
	else:
		max_health = 0
		health = 0
		if health_icon:
			health_icon.visible = false
		if health_label:
			health_label.text = ""
			health_label.visible = false
	loot_table = data.get("loot_table", [])
	attack = int(stats.get("attack", 0))
	armor = int(stats.get("armor", 0))
	attack_speed = float(stats.get("attack_speed", 0))
	if subtype == "peasant":
		if not has_node("PeasantInventory"):
			var inventory_scene = preload("res://Scenes/PeasantInventory.tscn")
			var inventory_instance = inventory_scene.instantiate()
			add_child(inventory_instance)
			inventory_instance.position = Vector2(0, 80)

# --- Hover signals ---
func _on_area_input_event(viewport: Object, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("ui_zoom_update", self)
