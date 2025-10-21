extends Card
class_name InventorySlot

@export var slot_type: String = ""
var attached_card: Card = null
var is_static: bool = true

func _process(delta):
	if attached_card and is_instance_valid(attached_card) and attached_card.is_equipped:
		if not attached_card.is_equipping:
			attached_card.global_position = global_position

func can_accept_card(card: Card) -> bool:
	if not is_visible_in_tree():
		return false
	if card.card_type != "equipment":
		return false
	if card.slot != slot_type:
		return false
	if attached_card != null:
		return false
	return true

func get_owner_card() -> Card:
	var parent = get_parent()
	while parent:
		if parent is Card:
			return parent
		parent = parent.get_parent()
	return null

func equip_card(card: Card) -> bool:
	if not can_accept_card(card):
		return false
	var card_manager = get_tree().root.get_node("Main/CardManager")
	card_manager.kill_card_tween(card)
	card.is_being_dragged = false
	attached_card = card
	card.attached_slot = self
	card.is_equipped = true
	card.is_equipping = true
	var owner_card = get_owner_card()
	if owner_card:
		modify_stats(owner_card, card, true)
		# --- Spawn weapon visual if equipping into weapon slot ---
		if slot_type == "weapon":
			var peasant_card = get_owner_card()  # This gets the Peasant card
			if peasant_card.has_node("EquippedWeapon"):
				peasant_card.get_node("EquippedWeapon").queue_free()
			var weapon_scene = preload("res://Scenes/Weapon.tscn")
			var weapon_instance = weapon_scene.instantiate()
			weapon_instance.scale = Vector2(3, 3)
			weapon_instance.name = "EquippedWeapon"
			# Add weapon as a child of the Peasant card so it can orbit
			peasant_card.add_child(weapon_instance)
			weapon_instance.position = Vector2(50, -100)
			print(peasant_card)
			# Load sprite + collision
			var weapon_data = CardDatabase.card_database.get(card.subtype, {})
			if weapon_data.has("sprite"):
				weapon_instance.get_node("Sprite2D").texture = weapon_data["sprite"]
			if weapon_data.has("weapon_polygon"):
				weapon_instance.get_node("Area2D/CollisionPolygon2D").polygon = weapon_data["weapon_polygon"]
			if weapon_data.has("polygon_offset"):
				weapon_instance.get_node("Area2D/CollisionPolygon2D").position = weapon_data["polygon_offset"]
	var tween = get_tree().create_tween()
	tween.tween_property(card, "global_position", global_position, card_manager.STACK_TWEEN_DURATION)\
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(card, "scale", Vector2(1, 1), card_manager.STACK_TWEEN_DURATION)\
		 .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		card.is_equipping = false
		visible = false
	)
	card_manager.card_tweens[card] = tween
	return true

func unequip_card():
	if attached_card and is_instance_valid(attached_card):
		var card_manager = get_tree().root.get_node("Main/CardManager")
		for stack in card_manager.all_stacks:
			if stack.has(self):
				stack.erase(attached_card)
				break
		var owner_card = get_owner_card()
		if owner_card:
			modify_stats(owner_card, attached_card, false)
			# --- Remove spawned weapon if unequipping from weapon slot ---
			if slot_type == "weapon" and owner_card.has_node("EquippedWeapon"):
				var weapon = owner_card.get_node("EquippedWeapon")
				if is_instance_valid(weapon):
					weapon.queue_free()
		card_manager.all_stacks.append([attached_card])
		attached_card.attached_slot = null
		attached_card.is_equipped = false
		attached_card = null
		visible = true

func modify_stats(owner: Card, equipment: Card, apply: bool = true) -> void:
	if not equipment.stats:
		return
	var direction := 1 if apply else -1
	# Handle additive stats
	if equipment.stats.has("add"):
		for key in equipment.stats["add"].keys():
			var value = equipment.stats["add"][key] * direction
			match key:
				"health":
					owner.max_health += value
					if owner.health > owner.max_health:
						owner.health = owner.max_health
					owner.set_health(owner.health) 
				"attack":
					owner.attack += value
				"armor":
					owner.armor += value
				"attack_speed":
					owner.attack_speed += value
	# Handle multiplicative stats (invert when removing)
	if equipment.stats.has("mul"):
		for key in equipment.stats["mul"].keys():
			var factor = float(equipment.stats["mul"][key])
			if apply:
				owner.set(key, owner.get(key) * factor)
			else:
				owner.set(key, owner.get(key) / factor)
