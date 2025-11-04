extends Node

signal night_started
signal day_started

const DAY_DURATION := 180.0
var day_timer := DAY_DURATION
var day_count := 1
var is_night := false

func _process(delta):
	if not is_night:
		day_timer -= delta * GameSpeedManager.current_speed
		if day_timer <= 0:
			start_night()

func start_night():
	is_night = true
	day_timer = 0
	print("🌙 Night has begun!")
	emit_signal("night_started")

func start_day():
	is_night = false
	day_timer = DAY_DURATION
	day_count += 1
	if SoundManager:
		SoundManager.play("new_day", 0.0)
	print("☀️ Day has begun!")
	print(day_count)
	emit_signal("day_started")

func get_day_count() -> int:
	return day_count
