extends Node

@onready var play_pause_button: TextureButton = $PlayPauseButton
@onready var speed2_button: TextureButton = $Speed2xButton
@onready var speed3_button: TextureButton = $Speed3xButton

# preload textures
var play_texture = preload("res://Images/play_button_active.png")
var pause_texture = preload("res://Images/pause_button.png")
var play_inactive_texture = preload("res://Images/play_button_inactive.png")
var speed2_active = preload("res://Images/2x_speed_button_active.png")
var speed2_inactive = preload("res://Images/2x_speed_button_inactive.png")
var speed3_active = preload("res://Images/3x_speed_button_active.png")
var speed3_inactive = preload("res://Images/3x_speed_button_inactive.png")

func _ready():
	# connect button signals
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	speed2_button.pressed.connect(_on_speed2_pressed)
	speed3_button.pressed.connect(_on_speed3_pressed)
	# connect to manager signal
	GameSpeedManager.connect("speed_changed", Callable(self, "_update_ui"))
	# initial UI update
	_update_ui()

func _update_ui(new_speed: float = -1):
	var speed = new_speed if new_speed >= 0 else GameSpeedManager.current_speed
	match speed:
		0.0:
			play_pause_button.texture_normal = pause_texture
		1.0:
			play_pause_button.texture_normal = play_texture
		2.0, 3.0:
			play_pause_button.texture_normal = play_inactive_texture
	speed2_button.texture_normal = speed2_active if speed == 2.0 else speed2_inactive
	speed3_button.texture_normal = speed3_active if speed == 3.0 else speed3_inactive
	speed2_button.disabled = (speed == 2.0)
	speed3_button.disabled = (speed == 3.0)

# -------------------------
# Button callbacks
# -------------------------
func _on_play_pause_pressed():
	GameSpeedManager.toggle_pause()

func _on_speed2_pressed():
	GameSpeedManager.set_speed(2.0)

func _on_speed3_pressed():
	GameSpeedManager.set_speed(3.0)
