extends Node2D
class_name EquipmentSlot

@export var allowed_type: String = "" 

var equipped_card: Card = null

func _ready() -> void:
	add_to_group("equipment_slots")

func get_global_rect() -> Rect2:
	var area = get_node_or_null("Area2D")
	if not area:
		return Rect2(global_position, Vector2.ZERO)
	var shape_node = area.get_node_or_null("CollisionShape2D")
	if not shape_node or not shape_node.shape:
		# fallback to area position if no shape
		return Rect2(area.global_position, Vector2.ZERO)
	var shape = shape_node.shape
	var pos = shape_node.get_global_position()
	if shape is RectangleShape2D:
		return Rect2(pos - shape.extents, shape.extents * 2)
	# Generic fallback for other shapes
	var aabb = shape.get_rect()
	aabb.position += pos
	return aabb

func can_accept(card: Card) -> bool:
	return equipped_card == null and card.card_type == "equipment" and card.slot == allowed_type

func equip(card: Card) -> void:
	if not can_accept(card):
		return
	# Remove from previous parent safely
	if card.get_parent():
		card.get_parent().remove_child(card)
	print("Slot global position:", global_position)
	print("Card global position before add_child:", card.global_position)
	add_child(card)
	card.position = Vector2.ZERO
	print("Card global position after add_child:", card.global_position)
	card.is_being_dragged = false
	equipped_card = card
	print("✅ Equipping card of type:", card.card_type, "slot:", card.slot, "Parent is now:", card.get_parent().name)

func unequip() -> void:
	if not equipped_card:
		print("Nothing to unequip")
		return
	var card_to_return = equipped_card
	equipped_card = null
	print("🛠 Unequipping card:", card_to_return.subtype)
	print("Card global pos before remove_child:", card_to_return.global_position)
	remove_child(card_to_return)
	var card_manager = get_tree().get_root().get_node("Main/CardManager") # adjust path
	card_manager.add_child(card_to_return)
	card_to_return.global_position = self.global_position
	card_to_return.is_being_dragged = false
	print("Card parent after reparent:", card_to_return.get_parent())
	print("Card global pos after reparent:", card_to_return.global_position)
	if card_manager.has_method("register_unequipped_card"):
		card_manager.register_unequipped_card(card_to_return)
