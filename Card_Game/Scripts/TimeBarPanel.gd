extends Panel

@onready var bar: TextureProgressBar = $TextureProgressBar
@onready var sprite: Sprite2D = $Sprite2D

var night_tween: Tween = null

func _ready():
	bar.value = 0
	bar.max_value = 100
	set_process(true)
	TimeManager.connect("night_started", Callable(self, "_on_night_started"))
	TimeManager.connect("day_started", Callable(self, "_on_day_started"))

func _process(delta):
	if not TimeManager:
		return
	if not TimeManager.is_night:
		var progress = 1.0 - (TimeManager.day_timer / TimeManager.DAY_DURATION)
		bar.value = progress * bar.max_value

# Called when night starts
func _on_night_started():
	if night_tween:
		night_tween.kill()
	night_tween = create_tween()
	night_tween.tween_property(bar, "value", 0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Reset bar when day starts
func _on_day_started():
	bar.value = 0
