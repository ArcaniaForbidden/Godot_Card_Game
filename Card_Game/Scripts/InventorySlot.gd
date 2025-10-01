extends Card
class_name InventorySlot

# Type of equipment this slot accepts
@export var slot_type: String = ""
var attached_card: Card = null
var is_static: bool = true

func _ready():
	print("InventorySlot ", name, " accepts slot type: ", slot_type)

func can_accept_card(card: Card) -> bool:
	if card.card_type != "equipment":
		return false
	if card.slot != slot_type:
		return false
	return true
