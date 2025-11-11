extends Control

const FILL_COLOR: Color = Color8(199, 131, 55)  # #c78337

@onready var fill = $Fill
@onready var label = $HungerLabel
@onready var background: Sprite2D = $Background
@onready var icon: Sprite2D = $HungerIcon
var icon_tween: Tween = null

func update_hunger(hunger: int, max_hunger: int) -> void:
	if max_hunger <= 0:
		visible = false
		return
	visible = true
	var ratio = clamp(float(hunger) / float(max_hunger), 0.0, 1.0)
	var bar_width = size.x * ratio
	fill.size.x = bar_width
	fill.modulate = FILL_COLOR
	label.text = "%d / %d" % [hunger, max_hunger]
	animate_hunger_icon()
	UIManager.refresh_card_ui()

func animate_hunger_icon():
	if not icon:
		return
	if icon_tween and icon_tween.is_valid():
		icon_tween.kill()
	icon_tween = get_tree().create_tween()
	icon_tween.tween_property(icon, "rotation_degrees", 10, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", -10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", 10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", -10, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	icon_tween.tween_property(icon, "rotation_degrees", 0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
