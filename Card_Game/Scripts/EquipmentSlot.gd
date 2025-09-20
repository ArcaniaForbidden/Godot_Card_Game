extends Node2D
class_name EquipmentSlot

@export var allowed_type: String = "" 
@export var active: bool = true

var equipped_card: Card = null

# --- Called when the game starts ---
func _ready() -> void:
	add_to_group("equipment_slots")

# --- Utility to get the Peasant card this slot belongs to ---
func get_owner_card() -> Card:
	var panel = get_parent() # EquipmentSlots
	if not panel:
		return null
	var equipment_node = panel.get_parent() # PeasantEquipment
	if not equipment_node:
		return null
	var peasant_card = equipment_node.get_parent() # Actual Peasant card
	if peasant_card and peasant_card is Card:
		return peasant_card
	return null

func get_global_rect() -> Rect2:
	var card_manager = get_tree().get_root().get_node("Main/CardManager")
	return card_manager.get_node_global_rect(self)

# --- Check if a card can be equipped in this slot ---
func can_accept(card: Card) -> bool:
	if not active:
		print("⛔", name, "is inactive, rejecting equip.")
		return false
	return equipped_card == null and card.card_type == "equipment" and card.slot == allowed_type

# --- Equip a card ---
func equip(card: Card) -> void:
	if not can_accept(card):
		return
	if card.get_parent():
		card.get_parent().remove_child(card)
	add_child(card)
	card.position = Vector2.ZERO
	card.is_being_dragged = false
	equipped_card = card
	print("✅ Equipping card:", card.subtype, "to slot:", name)

	# Update the stats of the owner Peasant card
	var owner = get_owner_card()
	if owner:
		_apply_equipment_stats(owner, card)

# --- Unequip the currently equipped card ---
func unequip() -> void:
	if not active:
		print("⛔", name, "is inactive, skipping unequip.")
		return
	if not equipped_card:
		print("Nothing to unequip")
		return
	
	var card_to_return = equipped_card
	equipped_card = null
	
	# Remove equipment stats from owner card
	var owner = get_owner_card()
	if owner and card_to_return:
		_remove_equipment_stats(owner, card_to_return)
	
	# Remove the equipment node from this slot and return to CardManager
	remove_child(card_to_return)
	var card_manager = get_tree().get_root().get_node("Main/CardManager")
	card_manager.add_child(card_to_return)
	card_to_return.global_position = global_position
	card_to_return.is_being_dragged = false
	
	if card_manager.has_method("register_unequipped_card"):
		card_manager.register_unequipped_card(card_to_return)
	print("🛠 Unequipped card:", card_to_return.subtype)

# --- Apply equipment stats to a Peasant card ---
func _apply_equipment_stats(owner: Card, equipment: Card) -> void:
	if not equipment.stats:
		return
	if equipment.stats.has("add"):
		for stat in equipment.stats["add"].keys():
			if owner.stats.has(stat):
				owner.stats[stat] += equipment.stats["add"][stat]
			else:
				owner.stats[stat] = equipment.stats["add"][stat]
	if equipment.stats.has("mul"):
		for stat in equipment.stats["mul"].keys():
			if owner.stats.has(stat):
				owner.stats[stat] *= equipment.stats["mul"][stat]
			else:
				owner.stats[stat] = equipment.stats["mul"][stat]
	_update_owner_properties(owner)

# --- Remove equipment stats from a Peasant card ---
func _remove_equipment_stats(owner: Card, equipment: Card) -> void:
	if not equipment.stats:
		return
	if equipment.stats.has("add"):
		for stat in equipment.stats["add"].keys():
			if owner.stats.has(stat):
				owner.stats[stat] -= equipment.stats["add"][stat]
	if equipment.stats.has("mul"):
		for stat in equipment.stats["mul"].keys():
			if owner.stats.has(stat):
				owner.stats[stat] /= equipment.stats["mul"][stat]
	_update_owner_properties(owner)

# --- Update the Card properties for easier access ---
func _update_owner_properties(owner: Card) -> void:
	owner.attack = int(owner.stats.get("attack", 0))
	owner.armor = int(owner.stats.get("armor", 0))
	owner.attack_speed = float(owner.stats.get("attack_speed", 1.0))
	if owner.stats.has("health"):
		owner.max_health = int(owner.stats["health"])
		if owner.health > owner.max_health:
			owner.set_health(owner.max_health)
