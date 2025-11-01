extends Node2D

@export var float_distance: float = 50.0
@export var duration: float = 1.2
@export var color: Color = Color(1, 0.2, 0.2)
@export var random_x_range: Vector2 = Vector2(-40, 40)
@export var random_y_range: Vector2 = Vector2(-40, 0)

@onready var label = $VisualLabel

func show_number(amount: int):
	label.label_settings = label.label_settings.duplicate()
	label.text = str(amount)
	label.visible = true
	label.label_settings.font_color = color
	var random_x = randf_range(random_x_range.x, random_x_range.y)
	var random_y = randf_range(random_y_range.x, random_y_range.y)
	position += Vector2(random_x, random_y)
	# Animate upwards and fade out
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - float_distance, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		queue_free()
	)
