extends Node2D
class_name EquipmentSlot

@export var allowed_type: String = ""        # e.g., "weapon", "helmet"
var equipped_card: Card = null               # The card currently in this slot
var owner_card: Card = null                  # The card that owns this inventory

func setup(owner: Card) -> void:
	owner_card = owner

# Check if a card can be equipped here
func can_accept(card: Card) -> bool:
	return card.card_type == "equipment" and card.slot == allowed_type

# Equip a card into this slot
func equip(card: Card) -> void:
	if card.card_type != "equipment" or card.slot != allowed_type:
		return
	# Unequip old card if any
	if equipped_card != null:
		unequip()
	# Parent the new card to this slot
	if card.get_parent():
		card.get_parent().remove_child(card)
	add_child(card)
	card.position = Vector2.ZERO
	card.is_being_dragged = false
	equipped_card = card
	_apply_equipment_stats(card)

# Unequip the card from this slot
func unequip() -> void:
	if equipped_card == null:
		return
	var card_to_return = equipped_card
	equipped_card = null
	_remove_equipment_stats(card_to_return)
	remove_child(card_to_return)
	var card_manager = get_tree().get_root().get_node("Main/CardManager")
	card_manager.add_child(card_to_return)
	card_to_return.global_position = global_position
	card_to_return.is_being_dragged = false

# Apply stats to owner card
func _apply_equipment_stats(equipment: Card) -> void:
	if not owner_card or not equipment.stats:
		return
	if equipment.stats.has("add"):
		for stat in equipment.stats["add"].keys():
			owner_card.stats[stat] = owner_card.stats.get(stat, 0) + equipment.stats["add"][stat]
	if equipment.stats.has("mul"):
		for stat in equipment.stats["mul"].keys():
			owner_card.stats[stat] = owner_card.stats.get(stat, 1) * equipment.stats["mul"][stat]
	_update_owner_properties()

# Remove stats from owner card
func _remove_equipment_stats(equipment: Card) -> void:
	if not owner_card or not equipment.stats:
		return
	if equipment.stats.has("add"):
		for stat in equipment.stats["add"].keys():
			owner_card.stats[stat] -= equipment.stats["add"][stat]
	if equipment.stats.has("mul"):
		for stat in equipment.stats["mul"].keys():
			owner_card.stats[stat] /= equipment.stats["mul"][stat]
	_update_owner_properties()

# Update Card properties for easy access
func _update_owner_properties() -> void:
	if not owner_card:
		return
	owner_card.attack = int(owner_card.stats.get("attack", 0))
	owner_card.armor = int(owner_card.stats.get("armor", 0))
	owner_card.attack_speed = float(owner_card.stats.get("attack_speed", 1.0))
	if owner_card.stats.has("health"):
		owner_card.max_health = int(owner_card.stats["health"])
		if owner_card.health > owner_card.max_health:
			owner_card.set_health(owner_card.max_health)
