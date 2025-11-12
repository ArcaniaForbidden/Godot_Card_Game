extends Control

@onready var fill = $Fill
@onready var label = $HealthLabel
@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $HealthIcon
var icon_tween: Tween = null

func update_health(current: int, max_health: int) -> void:
	if max_health <= 0:
		visible = false
		return
	visible = true
	var ratio = clamp(float(current) / float(max_health), 0.0, 1.0)
	var bar_width = size.x * ratio
	fill.size.x = bar_width
	label.text = "%d / %d" % [current, max_health]
	var color: Color
	if ratio > 0.5:
		# From yellow (0.5) to green (1.0)
		var t = (ratio - 0.5) / 0.5
		color = Color(0.1 * t, 1.0 - 0.1 * t, 0.0)
	else:
		# From red (0.0) to yellow (0.5)
		var t = ratio / 0.5
		color = Color(1.0, t, 0.0)
	fill.modulate = color
	animate_health_icon()
	UIManager.refresh_card_ui()

func animate_health_icon():
	if not icon or not is_instance_valid(icon):
		return
	if icon_tween and icon_tween.is_valid():
		icon_tween.kill()
	icon_tween = get_tree().create_tween()
	icon_tween.tween_property(icon, "rotation_degrees", 10, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", -10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", 10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", -10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", 0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func set_background_sprite(card_type: String) -> void:
	match card_type:
		"unit":
			background.texture = preload("res://Images/unit_health_bar.png")
		"building":
			background.texture = preload("res://Images/building_health_bar.png")
		"enemy":
			background.texture = preload("res://Images/enemy_health_bar.png")
		_:
			background.texture = preload("res://Images/unit_health_bar.png")
