extends Node2D

var master_volume_percentage: int = 100
var sound_volume_percentage: int = 100
var music_volume_percentage: int = 100

var current_hover_player: AudioStreamPlayer = null
var sounds = {
	"card_pickup": preload("res://Sounds/card_pickup.wav"),
	"card_drop": preload("res://Sounds/card_drop.wav"),
	"card_pop": preload("res://Sounds/card_pop.wav"),
	"card_pack_open": preload("res://Sounds/card_pack_open.wav"),
	"coin": preload("res://Sounds/coin.wav"),
	"damage": preload("res://Sounds/damage.wav"),
	"heal": preload("res://Sounds/heal.wav"),
	"sword_slash": preload("res://Sounds/sword_slash.wav"),
	"spear_thrust": preload("res://Sounds/spear_thrust.wav"),
	"claw_slash": preload("res://Sounds/claw_slash.wav"),
	"arrow": preload("res://Sounds/arrow.wav"),
	"ui_hover": preload("res://Sounds/ui_hover.wav"),
	"new_day": preload("res://Sounds/new_day.wav"),
	"raid_start": preload("res://Sounds/raid_start.wav"),
}

func play(sound_name: String, base_volume_db: float = 0.0, position = null) -> void:
	if not sounds.has(sound_name):
		return
	var is_hover_sound = sound_name == "ui_hover"
	if is_hover_sound and current_hover_player:
		if is_instance_valid(current_hover_player):
			current_hover_player.stop()
			current_hover_player.queue_free()
		current_hover_player = null
	var sfx
	if position != null and not is_hover_sound:
		sfx = AudioStreamPlayer2D.new()
		sfx.position = position
		sfx.attenuation = 0.5
	else:
		sfx = AudioStreamPlayer.new()
	sfx.stream = sounds[sound_name]
	# --- Determine category volume ---
	var category_volume_pct: int
	# You can define which sounds are "music" or "SFX"
	if sound_name in []: # example music
		category_volume_pct = music_volume_percentage
	else:
		category_volume_pct = sound_volume_percentage
	var final_volume_db = base_volume_db + percent_to_db(master_volume_percentage) + percent_to_db(category_volume_pct)
	sfx.volume_db = final_volume_db
	add_child(sfx)
	sfx.play()
	if is_hover_sound:
		current_hover_player = sfx
	var duration = sfx.stream.get_length()
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(sfx):
		sfx.queue_free()
	if is_hover_sound and current_hover_player == sfx:
		current_hover_player = null

# Converts 0-100% to Godot dB (-30dB to 0dB)
func percent_to_db(pct: float) -> float:
	return lerp(-30.0, 0.0, clampf(pct, 0, 100) / 100.0)
