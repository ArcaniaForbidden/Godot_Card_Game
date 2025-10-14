extends Card
class_name SellSlot

func sell_stack(stack: Array) -> void:
	var card_manager = get_tree().root.get_node("Main/CardManager")
	var total_value := 0
	var cards_to_remove := []
	# --- Determine which cards are sellable ---
	for c in stack:
		if not is_instance_valid(c):
			continue
		if c.value != null:
			total_value += c.value
			cards_to_remove.append(c)
		else:
			print("Card '%s' has no defined value, skipping" % c.subtype)
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
	# --- Spawn coins one at a time with tween and simulated drag ---
	var denominations = [
		{"name": "gold_coin", "value": 100},
		{"name": "silver_coin", "value": 10},
		{"name": "copper_coin", "value": 1},
	]
	for denom in denominations:
		while total_value >= denom.value:
			var spawn_pos = global_position + Vector2(0, -300)  # above SellSlot
			var final_pos = global_position + Vector2(0, 200)   # below SellSlot
			# Spawn coin
			var coin_card = card_manager.spawn_card(denom.name, spawn_pos)
			coin_card.is_being_simulated_dragged = true
			coin_card.z_index = card_manager.DRAG_Z_INDEX
			coin_card.scale = Vector2(1.1, 1.1)
			# Play coin sound
			if SoundManager:
				SoundManager.play("coin", -18.0)
			# --- Position tween ---
			var tween_pos = get_tree().create_tween()
			tween_pos.tween_property(coin_card, "position", final_pos, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# --- Scale tween (up then down) ---
			var tween_scale = get_tree().create_tween()
			tween_scale.tween_property(coin_card, "scale", Vector2(1.25, 1.25), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween_scale.tween_property(coin_card, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			# --- Finish callback ---
			tween_pos.finished.connect(Callable(func() -> void:
				if is_instance_valid(coin_card):
					coin_card.is_being_simulated_dragged = false
					card_manager.finish_drag_simulated([coin_card])
			))
			total_value -= denom.value
			await get_tree().create_timer(0.5).timeout
