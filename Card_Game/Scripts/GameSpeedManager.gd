extends Node

signal speed_changed(new_speed: float)

var current_speed: float = 1.0
var prev_speed: float = 1.0

func _ready():
	# Make sure we can handle input even if the game is paused
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = current_speed

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			Key.KEY_1:
				set_speed(1.0)
			Key.KEY_2:
				set_speed(2.0)
			Key.KEY_3:
				set_speed(3.0)
			Key.KEY_SPACE:
				toggle_pause()

func set_speed(speed: float) -> void:
	speed = max(speed, 0)
	if current_speed == speed:
		return
	if speed == 0.0:
		prev_speed = current_speed
	current_speed = speed
	Engine.time_scale = current_speed  # <-- Automatically scales everything
	emit_signal("speed_changed", current_speed)

func toggle_pause() -> void:
	if current_speed == 0.0:
		current_speed = prev_speed if prev_speed > 0 else 1.0
	else:
		prev_speed = current_speed
		current_speed = 0.0
	Engine.time_scale = current_speed
	emit_signal("speed_changed", current_speed)
