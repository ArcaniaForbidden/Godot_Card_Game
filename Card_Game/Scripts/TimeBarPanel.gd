extends Panel

@onready var bar: TextureProgressBar = $TextureProgressBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var time_icon: Sprite2D = $TimeIcon
@onready var next_day_button: TextureButton = $NextDayButton

var sun_image = preload("res://Images/sun.png")
var moon_image = preload("res://Images/moon.png")
var night_tween: Tween = null
var normal_color: Color = Color.BLACK
var hover_color: Color = Color.WHITE

func _ready():
	bar.value = 0
	bar.max_value = 100
	set_process(true)
	TimeManager.connect("night_started", Callable(self, "_on_night_started"))
	TimeManager.connect("day_started", Callable(self, "_on_day_started"))
	next_day_button.pressed.connect(Callable(self, "_on_next_day_button_pressed"))
	next_day_button.mouse_entered.connect(Callable(self, "_on_next_day_button_hovered").bind(next_day_button, true))
	next_day_button.mouse_exited.connect(Callable(self, "_on_next_day_button_hovered").bind(next_day_button, false))
	next_day_button.hide()

func _process(delta):
	if not TimeManager:
		return
	if not TimeManager.is_night:
		var progress = 1.0 - (TimeManager.day_timer / TimeManager.DAY_DURATION)
		bar.value = progress * bar.max_value

func _on_next_day_button_pressed():
	if next_day_button:
		next_day_button.disabled = true
	if TimeManager:
		TimeManager.start_day()
		if not next_day_button:
			return
		var tween := create_tween()
		tween.tween_property(next_day_button, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.finished.connect(func():
			if next_day_button:
				next_day_button.hide())

func _on_next_day_button_hovered(button: Control, hovered: bool) -> void:
	if hovered and SoundManager:
		SoundManager.play("ui_hover", 0.0)
	var label = button.get_node_or_null("Label")
	if not label:
		return
	if label.label_settings:
		label.label_settings = label.label_settings.duplicate()
	else:
		return
	label.label_settings.font_color = hover_color if hovered else normal_color

func _on_night_started():
	if night_tween:
		night_tween.kill()
	night_tween = create_tween()
	night_tween.tween_property(bar, "value", 0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	RaidManager.days_since_last_raid += 1
	RaidManager.roll_for_raid()
	set_night_icon()

func _on_day_started():
	bar.value = 0
	set_day_icon()

func set_day_icon():
	if time_icon:
		var tween = create_tween()
		tween.tween_property(time_icon, "modulate:a", 0.0, 0.3)
		await tween.finished
		time_icon.texture = sun_image
		tween = create_tween()
		tween.tween_property(time_icon, "modulate:a", 1.0, 0.3)

func set_night_icon():
	if time_icon:
		var tween = create_tween()
		tween.tween_property(time_icon, "modulate:a", 0.0, 0.3)
		await tween.finished
		time_icon.texture = moon_image
		tween = create_tween()
		tween.tween_property(time_icon, "modulate:a", 1.0, 0.3)
