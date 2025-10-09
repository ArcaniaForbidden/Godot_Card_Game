extends Card
class_name SellSlot

func sell_stack(stack: Array) -> void:
	var card_manager = get_tree().root.get_node("Main/CardManager")
	var total_value := 0
	var cards_to_remove := []
	var sold_stack := false
	# --- Determine which cards are sellable ---
	for c in stack:
		if not is_instance_valid(c):
			continue
		if c.value > 0:
			total_value += c.value
			cards_to_remove.append(c)
		else:
			print("Card '%s' has zero value, skipping" % c.subtype)
	# --- Remove sellable cards from stack and scene ---
	for c in cards_to_remove:
		stack.erase(c)
		for s in card_manager.all_stacks:
			if s.has(c):
				s.erase(c)
				if s.empty():
					card_manager.all_stacks.erase(s)
				break
		c.queue_free()
	# --- Spawn coins ---
	var denominations = [
		{"name": "gold_coin", "value": 100},
		{"name": "silver_coin", "value": 10},
		{"name": "copper_coin", "value": 1},
	]
	var spawn_pos = global_position
	for denom in denominations:
		while total_value >= denom.value:
			var coin_card = card_manager.spawn_card(denom.name, spawn_pos + Vector2(0, 100))
			total_value -= denom.value
			sold_stack = true
		if sold_stack:
			SoundManager.play("coin", -16.0)
