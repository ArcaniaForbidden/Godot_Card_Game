extends Node2D
class_name Card

signal hovered
signal hovered_off
signal ui_zoom_update(card: Card)
signal died(card: Card)

const LABEL_COLOR := Color.BLACK

var target_position: Vector2
var is_being_dragged: bool = false
var is_being_simulated_dragged: bool = false
var card_type: String = ""
var tags: Array = []
var subtype: String = ""
var display_name: String = ""
var weapon_type: String = ""
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
var is_dead: bool = false
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

func take_damage(amount: int):
	if is_dead:
		return
	# Subtract health and clamp
	health = clamp(health - amount, 0, max_health)
	if SoundManager:
		SoundManager.play("damage", -20.0)
	# Update the label like set_health
	if health_label:
		health_label.text = "%d/%d" % [health, max_health]
		health_label.self_modulate = LABEL_COLOR
	# Make sure icon is visible
	if health_icon:
		health_icon.visible = true
	print("%s took %d damage, remaining HP: %d" % [name, amount, health])
	if health <= 0:
		is_dead = true
		print("%s died!" % name)
		emit_signal("died", self)
		queue_free()

# --- Setup function ---
func setup(subtype_name: String) -> void:
	subtype = subtype_name
	target_position = position 
	var data = CardDatabase.card_database[subtype]
	card_type = data.get("card_type", "")
	display_name = data.get("display_name", subtype)
	weapon_type = data.get("weapon_type", "")
	print("Setup card '%s': card_type=%s, slot=%s" % [subtype, card_type, data.get("slot","")])
	# Set textures
	apply_foil_effect(data.get("rarity", ""))
	var is_animated = data.get("animated", false)
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
	self.tags = data.get("tags", [])
	# --- Show/hide value label and icon ---
	if card_type == "card_pack":
		if value_icon:
			value_icon.visible = false
		if value_label:
			value_label.visible = false
	elif value != null:
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
		var inventory_scene = preload("res://Scenes/UnitInventory.tscn")
		var inventory_instance = inventory_scene.instantiate()
		add_child(inventory_instance)
		inventory_instance.position = Vector2(0, 80)
	# --- Enemy Weapon Setup (multiple weapons) ---
	if card_type == "enemy" and data.has("weapons"):
		for weapon_entry in data["weapons"]:
			var weapon_data: Dictionary = {}
			if typeof(weapon_entry) == TYPE_STRING:
				# If it's a string, fetch weapon info from database
				weapon_data = CardDatabase.card_database.get(weapon_entry, {})
			elif typeof(weapon_entry) == TYPE_DICTIONARY:
				# Inline weapon definition
				weapon_data = weapon_entry.duplicate(true)
			else:
				continue
			var weapon_scene = preload("res://Scenes/Weapon.tscn")
			var weapon_instance = weapon_scene.instantiate()
			weapon_instance.name = "EnemyWeapon_" + weapon_data.get("name", str(randi()))
			weapon_instance.owner_card = self
			add_child(weapon_instance)
			# --- Transform / Visual ---
			weapon_instance.position = weapon_data.get("position", Vector2(40, -40))
			weapon_instance.scale = weapon_data.get("weapon_scale", Vector2(3, 3))
			if weapon_data.has("sprite"):
				weapon_instance.get_node("Sprite2D").texture = weapon_data["sprite"]
			if weapon_data.has("weapon_polygon"):
				weapon_instance.get_node("Area2D/CollisionPolygon2D").polygon = weapon_data["weapon_polygon"]
			if weapon_data.has("polygon_offset"):
				weapon_instance.get_node("Area2D/CollisionPolygon2D").position = weapon_data["polygon_offset"]
			# --- Weapon mechanics ---
			weapon_instance.weapon_type = weapon_data.get("weapon_type", "melee")
			weapon_instance.melee_type = weapon_data.get("melee_type", "lunge")
			weapon_instance.weapon_attack_sound = weapon_data.get("weapon_attack_sound", {})
			if weapon_data.has("weapon_stats") or weapon_data.has("stats"):
				var w_stats = weapon_data.get("weapon_stats", weapon_data.get("stats", {}))
				var add_stats = w_stats.get("add", {})
				if add_stats.has("attack"):
					weapon_instance.damage = add_stats["attack"]
				if add_stats.has("attack_speed"):
					weapon_instance.attack_cooldown = 1.0 / add_stats["attack_speed"]
				if add_stats.has("attack_range"):
					weapon_instance.attack_range = add_stats["attack_range"]
			if weapon_data.has("projectile_sprite"):
				weapon_instance.projectile_sprite = weapon_data["projectile_sprite"]
				weapon_instance.projectile_sound = weapon_data["projectile_sound"]
				weapon_instance.projectile_speed = weapon_data.get("projectile_speed", 500.0)
				weapon_instance.projectile_lifetime = weapon_data.get("projectile_lifetime", 1.0)
				weapon_instance.projectile_polygon = weapon_data.get("projectile_polygon", [])

# --- Hover signals ---
func _on_area_input_event(viewport: Object, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("ui_zoom_update", self)
