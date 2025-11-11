extends Node2D
class_name Card

signal hovered
signal hovered_off
signal ui_zoom_update(card: Card)
signal died(card: Card)

var target_position: Vector2
var is_being_dragged: bool = false
var is_being_simulated_dragged: bool = false
var card_type: String = ""
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
var attack_speed: float = 0.0          # default attacks per second
var idle_timer: float = 0.0
var min_jump_time: float = 1.5
var max_jump_time: float = 2.5
var jump_distance: float = 150.0
var in_battle: bool = false
var is_dead: bool = false
var is_equipped: bool = false
var is_equipping: bool = false
var attached_slot: InventorySlot = null
var loot_table: Array = []
var damage_flash_tween: Tween = null
var new_building: bool = true
var health_bar: Control = null
var hunger_bar: Control = null
var max_hunger: int = 0
var hunger: int = 0
var hunger_timer: float = 0.0
var hunger_interval: float = 5.0
var starving: bool = false
var starvation_timer: float = 0.0
var starvation_interval: float = 5.0
var food_value = null
var tame_chance = 0.25

# --- UI references ---
@onready var animation_manager: AnimationManager = AnimationManager.new()
@onready var display_name_label: Label = get_node_or_null("DisplayNameLabel")
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
@onready var health_bar_scene: PackedScene = preload("res://Scenes/HealthBar.tscn")
@onready var hunger_bar_scene: PackedScene = preload("res://Scenes/HungerBar.tscn")

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
	if max_hunger > 0:
		if TimeManager.is_night:
			return
		hunger_timer += delta * GameSpeedManager.current_speed
		if hunger_timer >= hunger_interval:
			hunger_timer = 0.0
			_on_hunger_tick()
	if starving:
		if TimeManager.is_night:
			return
		starvation_timer += delta * GameSpeedManager.current_speed
		if starvation_timer >= starvation_interval:
			starvation_timer = 0.0
			print("%s is starving!" % name)
			take_damage(1)
			update_hunger_bar()

# --- Helpers ---
func _on_hunger_tick() -> void:
	if hunger > 0:
		hunger -= 1
		if hunger == 0:
			starving = true
			starvation_timer = 0.0  # start counting until next damage
	else:
		starving = true  # already 0
	update_hunger_bar()

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
	flash_damage_effect()
	# Subtract health and clamp
	health = clamp(health - amount, 0, max_health)
	if SoundManager:
		SoundManager.play("damage", -16.0, global_position)
	# Update the label like set_health
	if health_label:
		health_label.text = "%d" % [health]
	# Make sure icon is visible
	if health_icon:
		health_icon.visible = true
	if is_inside_tree():
		var damage_number_scene = preload("res://Scenes/VisualNumber.tscn")
		var damage_number_instance = damage_number_scene.instantiate()
		get_parent().add_child(damage_number_instance)
		damage_number_instance.global_position = global_position + Vector2(0, -70)
		damage_number_instance.z_index = 1000
		damage_number_instance.show_number(amount, Color(1, 0.2, 0.2))
	print("%s took %d damage, remaining HP: %d" % [name, amount, health])
	if health <= 0:
		is_dead = true
		print("%s died!" % name)
		emit_signal("died", self)
		queue_free()
	update_health_bar()

func heal(amount: int) -> void:
	if health >= max_health:
		return  # no healing needed
	var healing = min(amount, max_health - health)
	if healing <= 0:
		return
	health += healing
	if health_label:
		health_label.text = "%d" % [health]
	if health_icon:
		health_icon.visible = true
	if is_inside_tree():
		var heal_number_scene = preload("res://Scenes/VisualNumber.tscn")
		var heal_number_instance = heal_number_scene.instantiate()
		get_parent().add_child(heal_number_instance)
		heal_number_instance.global_position = global_position + Vector2(0, -70)
		heal_number_instance.z_index = 1000
		heal_number_instance.show_number(healing, Color(0.3, 1.0, 0.3)) # only show actual healing
	update_health_bar()

func flash_damage_effect():
	if not is_inside_tree():
		return
	# Cancel any existing flash
	if damage_flash_tween and damage_flash_tween.is_valid():
		damage_flash_tween.kill()
		modulate = Color(1, 1, 1)  # Reset to normal color
	var original_modulate := modulate
	modulate = Color(1, 0.2, 0.2) # Flash red
	# Create new tween
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property(self, "modulate", original_modulate, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func update_health_bar() -> void:
	if health_bar:
		health_bar.update_health(health, max_health)

func update_hunger_bar() -> void:
	if hunger_bar:
		hunger_bar.update_hunger(hunger, max_hunger)

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
		if card_pack_label2:
			card_pack_label2.visible = true
			card_pack_label2.text = "Card Pack"
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
		display_name_label.text = display_name
	if card_type == "equipment":
		slot = data.get("slot", "")
	else:
		slot = ""
	# --- Set value from card data ---
	if data.has("value"):
		value = int(data["value"])
	else:
		value = null
	# --- Set food value from card data ---
	if card_type == "food" and data.has("food_value"):
		food_value = int(data["food_value"])
	else:
		food_value = null
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
	else:
		if value_icon:
			value_icon.visible = false
		if value_label:
			value_label.visible = false
	# --- Stats setup ---
	stats = data.get("stats", {}).duplicate(true)
	if stats.has("health") and stats["health"] > 0:
		max_health = int(stats["health"])
		health = max_health
		health_bar = health_bar_scene.instantiate()
		add_child(health_bar)
		health_bar.position = Vector2(-47, 70)
		health_bar.set_background_sprite(card_type)
		update_health_bar()
	loot_table = data.get("loot_table", [])
	if stats.has("attack"):
		attack = int(stats["attack"])
	if stats.has("armor"):
		armor = int(stats["armor"])
	if stats.has("attack_speed"):
		attack_speed = int(stats["attack_speed"])
	if stats.has("hunger"):
		max_hunger = int(stats["hunger"])
		hunger = max_hunger
		hunger_timer = 0.0
		hunger_bar = hunger_bar_scene.instantiate()
		add_child(hunger_bar)
		hunger_bar.position = Vector2(-47, 88)
		update_hunger_bar()
	if stats.has("min_jump_time"):
		min_jump_time = int(stats["min_jump_time"])
	if stats.has("max_jump_time"):
		max_jump_time = int(stats["max_jump_time"])
	if stats.has("jump_distance"):
		jump_distance = int(stats["jump_distance"])
	if card_type == "unit" and subtype == "peasant":
		var inventory_scene = preload("res://Scenes/UnitInventory.tscn")
		var inventory_instance = inventory_scene.instantiate()
		add_child(inventory_instance)
		inventory_instance.position = Vector2(0, 60)
	if card_type == "neutral" and data.has("tame_chance"):
		tame_chance = float(data.get("tame_chance", null))
	# --- Enemy Weapon Setup (multiple weapons) ---
	if card_type == "enemy" and data.has("weapons"):
		for weapon_entry in data["weapons"]:
			var weapon_data: Dictionary = {}
			if typeof(weapon_entry) == TYPE_STRING:
				weapon_data = CardDatabase.card_database.get(weapon_entry, {})
			elif typeof(weapon_entry) == TYPE_DICTIONARY:
				weapon_data = weapon_entry.duplicate(true)
			else:
				continue
			var weapon_path = "res://Scenes/Weapon.tscn"
			var weapon_scene = load(weapon_path)
			if weapon_scene == null:
				push_error("⚠️ Failed to load weapon scene at path: " + weapon_path)
				continue
			var weapon_instance = weapon_scene.instantiate()
			if weapon_instance == null:
				push_error("⚠️ Failed to instantiate weapon scene for: " + str(weapon_data))
				continue
			weapon_instance.name = "EnemyWeapon_" + weapon_data.get("name", str(randi()))
			weapon_instance.owner_card = self
			add_child(weapon_instance)
			# --- Transform / Visual ---
			weapon_instance.position = weapon_data.get("position", Vector2(40, -40))
			weapon_instance.scale = weapon_data.get("weapon_scale", Vector2(3, 3))
			if weapon_data.has("sprite"):
				var sprite_node = weapon_instance.get_node_or_null("Sprite2D")
				if sprite_node:
					sprite_node.texture = weapon_data["sprite"]
			if weapon_data.has("weapon_polygon"):
				var poly_node = weapon_instance.get_node_or_null("Area2D/CollisionPolygon2D")
				if poly_node:
					poly_node.polygon = weapon_data["weapon_polygon"]
			if weapon_data.has("polygon_offset"):
				var poly_node = weapon_instance.get_node_or_null("Area2D/CollisionPolygon2D")
				if poly_node:
					poly_node.position = weapon_data["polygon_offset"]
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
				weapon_instance.projectile_sound = weapon_data.get("projectile_sound", {})
				weapon_instance.projectile_speed = weapon_data.get("projectile_speed", 500.0)
				weapon_instance.projectile_lifetime = weapon_data.get("projectile_lifetime", 1.0)
				weapon_instance.projectile_polygon = weapon_data.get("projectile_polygon", [])

# --- Hover signals ---
func _on_area_input_event(viewport: Object, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("ui_zoom_update", self)
