extends Node

signal night_started
signal day_started

const DAY_DURATION := 30.0
var day_timer := DAY_DURATION
var is_night := false

func _ready():
	set_process(true)

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
	print("☀️ Day has begun!")
	emit_signal("day_started")
